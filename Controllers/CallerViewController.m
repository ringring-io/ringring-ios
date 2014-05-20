//
//  CallerViewController.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 14/01/2014.
//
//

#import "CallerViewController.h"
#import "UIViewControllerWithStatusBar.h"
#import "LinphoneManager.h"

#import "LinphoneHelper.h"
#import "AddressBookMap.h"



@interface CallerViewController () {
    BOOL callErrorDetected;
    BOOL activeCallIsInProgress;
    BOOL callTimerStarted;
    BOOL callSecurityTimerStarted;
    int callDuration;
    NSTimer *callTimer;
    NSTimer *callSecurityTimer;
}

@end



@implementation CallerViewController

@synthesize callType;
@synthesize incomingCall;
@synthesize contact;

@synthesize registrationStateImage;
@synthesize registrationStateLabel;
@synthesize registeredUserLabel;

@synthesize contactEmail;
@synthesize callStatusLabel;
@synthesize zrtpHashLabel;
@synthesize contactImageView;
@synthesize securityImageView;
@synthesize callTimerLabel;

@synthesize declineButton;
@synthesize acceptButton;
@synthesize hangupButton;



#pragma mark - Initialisers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



#pragma mark - Lifecycle Functions

- (void)viewDidLoad
{
    [super viewDidLoadWithRegistrationStateLabel:registrationStateLabel
                          registrationStateImage:registrationStateImage
                            registeredEmailLabel:registeredUserLabel
                performedSegueIdentifierAtIncall:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
     
    // Set observer - Call update listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdate:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
    
    if (!activeCallIsInProgress) {
        switch (callType) {
            case kIncoming:
                [self initIncomingCall];
                break;
        
            case kOutgoing:
                [self initOutgoingCall];
                break;
            
            case kNone:
                break;
        }
    }
    
    // Init Call Timer
    [self initCallTimer];
    
    // Init Call Security Timer
    [self initCallSecurityTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove observer - Call update listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneCallUpdate
                                                  object:nil];
    
    // Stop Call Timer
    [self stopCallTimer];
    
    // Stop Call Security Timer
    [self stopCallSecurityTimer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Update Event Functions

// Call observer actions
- (void)callUpdate:(NSNotification*)notif {
    LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
    LinphoneCallState callState = [[notif.userInfo objectForKey: @"state"] intValue];
    NSString *message = [notif.userInfo objectForKey:@"message"];
    
    NSString *callStatus;
    
    BOOL refreshUI = NO;
    //bool canHideInCallView = (linphone_core_get_calls([LinphoneManager getLc]) == NULL);
    
    // Don't handle call state during incoming call view
    /*
     if([[self currentView] equal:[IncomingCallViewController compositeViewDescription]] && state != LinphoneCallError && state != LinphoneCallEnd) {
     return;
     }
     */
    
	switch (callState) {
        case LinphoneCallIncomingReceived:      //  1: This is a new incoming call */
        {
            NSLog(@"========= CALL_UPDATE: INCOMING =========");
            break;
        }
        case LinphoneCallOutgoingInit:          //  2: An outgoing call is started */
        {
            NSLog(@"========= CALL_UPDATE: OUTGOING_INIT =========");
            callStatus = NSLocalizedString(@"Connecting..", nil);
            refreshUI = YES;
			break;
        }
        case LinphoneCallOutgoingRinging:       //  4: An outgoing call is ringing at remote end */
        {
            NSLog(@"========= CALL_UPDATE: RINGING =========");
            callStatus = NSLocalizedString(@"Ringing..", nil);
            refreshUI = YES;
            break;
        }
        case LinphoneCallConnected:             //  6: Connected, the call is answered */
        case LinphoneCallStreamsRunning:        //  7: The media streams are established and running*/
        {
            NSLog(@"========= CALL_UPDATE: CONNECTED/STREAMS RUNNING [%d] =========", callState);
            // Reset and start call timer
            [callTimerLabel setText:[self secondsToString:0]];
            callTimerStarted = YES;
            callSecurityTimerStarted = YES;
            break;
        }
        case LinphoneCallError:                 // 12: The call encountered an error*/
        {
            NSLog(@"========= CALL_UPDATE: CALL_ERROR =========");
            callErrorDetected = YES;
            [self displayCallError:call message:message];
        }
        case LinphoneCallEnd:                   // 13: The call ended normally*/
        {
            NSLog(@"========= CALL_UPDATE: CALL_END =========");
            [self clearActiveCall];
            
             // Close call view if no error alert detected
             if (!callErrorDetected) {
                [self dismissViewControllerAnimated:YES completion:nil];
             }
			break;
        }
            
            // Unused call states
        case LinphoneCallIdle:                  //  0: Initial call state */
        case LinphoneCallOutgoingProgress:      //  3: An outgoing call is in progress */
        case LinphoneCallOutgoingEarlyMedia:    //  5: An outgoing call is proposed early media */
        case LinphoneCallPausing:               //  8: The call is pausing at the initiative of local end */
        case LinphoneCallPaused:                //  9: The call is paused, remote end has accepted the pause */
        case LinphoneCallResuming:              // 10: The call is being resumed by local end*/
        case LinphoneCallRefered:               // 11: The call is being transfered to another party, resulting in a new outgoing call to follow immediately*/
        case LinphoneCallPausedByRemote:        // 14: The call is paused by remote end*/
        case LinphoneCallUpdatedByRemote:       // 15: The call's parameters change is requested by remote end, used for example when video is added by remote */
        case LinphoneCallIncomingEarlyMedia:    // 16: We are proposing early media to an incoming call */
        case LinphoneCallUpdating:              // 17: A call update has been initiated by us */
        case LinphoneCallReleased:              // 18: The call object is no more retained by the core */
        {
            NSLog(@"=============================== %d ================= ", callState);
            break;
        }
        default:
            break;
	}
    
    // Update call status UI elements if needed
    if (refreshUI) {
        [self updateUICallStatus:callStatus
                        zrtpHash:nil];
    }
    
    //[self updateApplicationBadgeNumber];
}



#pragma mark - User Event Functions

- (IBAction)acceptButtonTapped:(id)sender {
    [self acceptIncomingCall];
}

- (IBAction)declineButtonTapped:(id)sender {
    [self hangupCall];
}

- (IBAction)hangupButtonTapped:(id)sender {
    [self hangupCall];
}



#pragma mark - Update UI Functions

// Update registration status IBOutlet element references
- (void)updateUICallStatus:(NSString *)callStatus zrtpHash:(NSString *)zrtpHash
{
    [callStatusLabel setText:callStatus];
    [zrtpHashLabel setText:zrtpHash];
}

- (void)displayCallError:(LinphoneCall *)call message:(NSString *)message {
    const char* lUserNameChars=linphone_address_get_username(linphone_call_get_remote_address(call));
    NSString* lUserName = lUserNameChars?[[[NSString alloc] initWithUTF8String:lUserNameChars] init]:NSLocalizedString(@"Unknown",nil);
    NSString* lMessage;
    NSString* lTitle;
 
    NSString *lDisplayName = [lUserName stringByReplacingOccurrencesOfString:@"%40" withString:@"@"];
 
    //get default proxy
    LinphoneProxyConfig* proxyCfg;
    linphone_core_get_default_proxy([LinphoneManager getLc],&proxyCfg);
    if (proxyCfg == nil) {
 
        lMessage = NSLocalizedString(@"Please make sure your device is connected to the internet and double check your SIP account configuration in the settings.", nil);
    } else {
        lMessage = [NSString stringWithFormat : NSLocalizedString(@"Cannot call %@", nil), lDisplayName];
    }
 
    if (linphone_call_get_reason(call) == LinphoneReasonNotFound) {
        lMessage = [NSString stringWithFormat : NSLocalizedString(@"'%@' not registered", nil), lDisplayName];
    }
    else {
        if (message != nil) {
            lMessage = [NSString stringWithFormat : NSLocalizedString(@"%@\nReason was: %@", nil), lMessage, message];
        }
    }
 
    lTitle = NSLocalizedString(@"Call failed",nil);
 
    UIAlertView* error = [[UIAlertView alloc] initWithTitle:lTitle
                                                    message:lMessage
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Dismiss",nil)
                                          otherButtonTitles:nil];

    [error show];
}
 
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self clearActiveCall];
    
    // dismiss call view
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark -

- (void)initIncomingCall {
    NSString *email = nil;
    Contact *incomingContact = nil;
    
    // Get caller address
    const LinphoneAddress* addr = linphone_call_get_remote_address(incomingCall);
    
    if (addr != NULL) {
        const char* lUserName = linphone_address_get_username(addr);
        NSString *sipUser = [[NSString alloc] initWithCString:lUserName encoding:NSUTF8StringEncoding];
        
        // Try to get caller id from address book
        email = [LinphoneHelper sipUserToEmail:sipUser];
        incomingContact = [AddressBookMap getContactWithEmail:email];

    }
    // If the email is not in the address book than create a default contact
    if (!incomingContact) {
        incomingContact = [[Contact alloc] initWithDefault:email];
    }
    
    // Update UI elements with caller details
    contactEmail.title = incomingContact.email;
    contactImageView.image = incomingContact.image;
    
    // Reset call status UI elements
    [self updateUICallStatus: NSLocalizedString(@"Incoming call..", nil)
                    zrtpHash:nil];

    // Hide security image
    [securityImageView setHidden:TRUE];
    
    // Hide call timer with the caller name
    [callTimerLabel setText:incomingContact.email];
    
    // Hide/unhide call specific buttons
    [hangupButton setHidden:YES];
    [declineButton setHidden:NO];
    [acceptButton setHidden:NO];

    // Set active call is in progress flag
    activeCallIsInProgress = YES;
    
    // Reset timers started flag
    callTimerStarted = NO;
    callSecurityTimerStarted = NO;
}

- (void)initOutgoingCall {
    
    contactEmail.title = contact.email;
    contactImageView.image = contact.image;
    
    NSString *address = [contact.email stringByReplacingOccurrencesOfString:@"@" withString:@"%40"];
    NSString *displayName = contact.fullName;
    
    [[LinphoneManager instance] call:address displayName:displayName transfer:FALSE];
    
    // Reset call status UI elements
    [self updateUICallStatus:NSLocalizedString(@"Connecting..", nil)
                    zrtpHash:nil];
    
    // Hide security image
    [securityImageView setHidden:TRUE];
    
    // Hide call timer
    [callTimerLabel setText:nil];
    
    // Hide/unhide call specific buttons
    [hangupButton setHidden:NO];
    [declineButton setHidden:YES];
    [acceptButton setHidden:YES];
  
    // Set active call is in progress flag
    activeCallIsInProgress = YES;
    
    // Reset timers started flag
    callTimerStarted = NO;
    callSecurityTimerStarted = NO;
}

- (void)acceptIncomingCall {
    
    // Hide/unhide call specific buttons
    [hangupButton setHidden:YES];
    [declineButton setHidden:YES];
    [acceptButton setHidden:YES];
    
    //
    [self updateUICallStatus:NSLocalizedString(@"Accepting..", nil)
                    zrtpHash:nil];

    //
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[LinphoneManager instance] acceptCall:incomingCall];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            
            // Reset and start call timers
            [callTimerLabel setText:[self secondsToString:0]];
            callTimerStarted = YES;
            callSecurityTimerStarted = YES;
            
            // Hide/unhide call specific buttons
            [hangupButton setHidden:NO];
            [declineButton setHidden:YES];
            [acceptButton setHidden:YES];
        });
    });
}

- (void)hangupCall {
    if([LinphoneManager isLcReady]) {
        LinphoneCore* lc = [LinphoneManager getLc];
        LinphoneCall* currentcall = linphone_core_get_current_call(lc);
        if(currentcall != NULL) { // In a call
            linphone_core_terminate_call(lc, currentcall);
        } else {
            const MSList* calls = linphone_core_get_calls(lc);
            if (ms_list_size(calls) == 1) { // Only one call
                linphone_core_terminate_call(lc,(LinphoneCall*)(calls->data));
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
        [self clearActiveCall];
    } else {
        [LinphoneHelper logc:LinphoneLoggerWarning format:"Cannot trigger hangup button: Linphone core not ready"];
    }
}

- (NSString *)secondsToString:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = totalSeconds / 60 % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

- (void)clearActiveCall {
    activeCallIsInProgress = NO;
    incomingCall = nil;
    callType = kNone;
}



#pragma mark - Call Timer Functions

- (void)initCallTimer {
    callTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                 target:self
                                               selector:@selector(updateUICallTimer:)
                                               userInfo:nil
                                                repeats:TRUE];
}

- (void)updateUICallTimer:(NSTimer *) aTimer {
    
    if (callTimerStarted) {
        [zrtpHashLabel setText:nil];
        [callTimerLabel setText:[self secondsToString:++callDuration]];
        
        // Hide/unhide call specific buttons
        [hangupButton setHidden:NO];
        [declineButton setHidden:YES];
        [acceptButton setHidden:YES];
    }
}

- (void)stopCallTimer {
    callTimerStarted = NO;
    
    if (callTimer) {
        [callTimer invalidate];
        callTimer = nil;
    }
}



#pragma mark - Call Security Timer Functions

- (void)initCallSecurityTimer {
    callSecurityTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                         target:self
                                                       selector:@selector(updateUICallSecurityTimer:)
                                                       userInfo:nil
                                                        repeats:TRUE];
}

- (void)updateUICallSecurityTimer:(NSTimer *) theTimer {
    BOOL pending = false;
    BOOL security = true;
    
    // Default is non secure
    [zrtpHashLabel setText:@""];
    securityImageView.image = [UIImage imageNamed:@"secure_not_ok.png"];
    
    if(![LinphoneManager isLcReady]) {
        return;
    }
    const MSList *list = linphone_core_get_calls([LinphoneManager getLc]);
    if(list == NULL) {
        return;
    }
    
    if (callSecurityTimerStarted) {
        [securityImageView setHidden:FALSE];

        [callStatusLabel setText:NSLocalizedString(@"Securing handshake..", nil)];
        [zrtpHashLabel setText:NSLocalizedString(@"Waiting..", nil)];
    
        while(list != NULL) {
            LinphoneCall *call = (LinphoneCall*) list->data;
            LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
            if(enc == LinphoneMediaEncryptionNone)
                security = false;
            else if(enc == LinphoneMediaEncryptionZRTP) {
                if(!linphone_call_get_authentication_token_verified(call)) {
                    pending = true;
                }
            
                [callStatusLabel setText:NSLocalizedString(@"Secure call code:", nil)];
                NSString *zrtpHash = [[[NSString alloc] initWithUTF8String:linphone_call_get_authentication_token(call)] uppercaseString];
                
                [zrtpHashLabel setText:zrtpHash];
                securityImageView.image = [UIImage imageNamed:@"secure_ok.png"];
            }
            list = list->next;
        }
    }
    
    /*
    if(security) {
        
        if(pending) {
            [callSecurityImage setImage:[UIImage imageNamed:@"security_pending.png"]];
        } else {
            [callSecurityImage setImage:[UIImage imageNamed:@"security_ok.png"]];
        }
    } else {
        [callSecurityImage setImage:[UIImage imageNamed:@"security_ko.png"]];
    }
    [callSecurityImage setHidden: false];
    */
}

- (void)stopCallSecurityTimer {
    callSecurityTimerStarted = NO;
    
    if (callSecurityTimer) {
        [callSecurityTimer invalidate];
        callSecurityTimer = nil;
    }
}
@end
