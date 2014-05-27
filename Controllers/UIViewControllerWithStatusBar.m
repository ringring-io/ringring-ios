//
//  StatusBarViewController.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 15/01/2014.
//
//

#import "UIViewControllerWithStatusBar.h"
#import "CallerViewController.h"

#import "LinphoneHelper.h"
#import "LinphoneManager.h"



@interface UIViewControllerWithStatusBar () {
    UILabel *sbRegistrationStateLabel;
    UIImageView *sbRegistrationStateImageView;
    UILabel *sbRegisteredEmailLabel;
    NSString *performedSegueIdentiferAtIncall;
    
    LinphoneCall *call;
}

@end



@implementation UIViewControllerWithStatusBar

#pragma mark - Initialization Functions

// Init status bar UI elements
- (id)viewDidLoadWithRegistrationStateLabel:(UILabel *)registrationStateLabel
                     registrationStateImage:(UIImageView *)registrationStateImage
                        registeredEmailLabel:(UILabel *)registeredEmailLabel
           performedSegueIdentifierAtIncall:(NSString *)performedSegueIdentifierAtIncall
{
    [super viewDidLoad];

    sbRegistrationStateLabel = registrationStateLabel;
    sbRegistrationStateImageView = registrationStateImage;
    sbRegisteredEmailLabel = registeredEmailLabel;
    performedSegueIdentiferAtIncall = performedSegueIdentifierAtIncall;
    
    return self;
}



#pragma mark - Lifecycle Functions

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Set observer - Registration update listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdateOnStatusBar:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    // Set observer - Call update listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdateOnStatusBar:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
    
    // Force to refresh the statuses when the view appears
    LinphoneProxyConfig* proxyCfg = NULL;
    if([LinphoneManager isLcReady])
        linphone_core_get_default_proxy([LinphoneManager getLc], &proxyCfg);
    [self proxyConfigUpdate: proxyCfg];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove observer - Registration update listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneRegistrationUpdate
                                                  object:nil];
    
    // Remove observer - Call update listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneCallUpdate
                                                  object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Update Event Functions

// Registration observer actions
- (void)registrationUpdateOnStatusBar: (NSNotification*) notif {
    LinphoneProxyConfig *proxyCfg = [[notif.userInfo objectForKey: @"cfg"] pointerValue];
    
    [self proxyConfigUpdate:proxyCfg];
}

// Check the the proxy configuration actual status and update statusbar values
- (void)proxyConfigUpdate: (LinphoneProxyConfig*) proxyCfg {
    LinphoneRegistrationState state;
    NSString* registrationStatus;
    NSString* registeredEmail;
    UIImage* registrationStatusImage;
    
    // Set registration status message
    if (proxyCfg == NULL) {
        state = LinphoneRegistrationNone;
        if(![LinphoneManager isLcReady] || linphone_core_is_network_reachable([LinphoneManager getLc]))
            registrationStatus = NSLocalizedString(@"No SIP account configured", nil);
        else
            registrationStatus = NSLocalizedString(@"Network down", nil);
    } else {
        state = linphone_proxy_config_get_state(proxyCfg);
        
        switch (state) {
            case LinphoneRegistrationOk:
                registrationStatus = NSLocalizedString(@"Online", nil);
                registrationStatusImage = [UIImage imageNamed:@"led_online.png"];
                registeredEmail = [LinphoneHelper registeredEmail];
                break;
            case LinphoneRegistrationNone:
            case LinphoneRegistrationCleared:
                registrationStatus =  NSLocalizedString(@"Offline", nil);
                registrationStatusImage = [UIImage imageNamed:@"led_offline.png"];
                registeredEmail = nil;
                break;
            case LinphoneRegistrationFailed:
                registrationStatus =  NSLocalizedString(@"Login failed", nil);
                registrationStatusImage = [UIImage imageNamed:@"led_login_failed.png"];
                registeredEmail = nil;
                break;
            case LinphoneRegistrationProgress:
                registrationStatus =  NSLocalizedString(@"Logging in..", nil);
                registrationStatusImage = [UIImage imageNamed:@"led_logging_in.png"];
                registeredEmail = nil;
                break;
            default: break;
        }
    }
    
    // Update statusbar UI elements
    [self updateUIRegistrationStatus:registrationStatus
         withRegistrationStatusImage:registrationStatusImage
                 withRegisteredEmail:registeredEmail];
}

// Call observer actions
- (void)callUpdateOnStatusBar:(NSNotification*)notif {
    LinphoneCall *aCall = [[notif.userInfo objectForKey: @"call"] pointerValue];
    LinphoneCallState callState = [[notif.userInfo objectForKey: @"state"] intValue];
    
	switch (callState) {
        case LinphoneCallIncomingReceived:      //  1: This is a new incoming call
        {
            // Switch to incoming call window
            if(performedSegueIdentiferAtIncall != nil) {
                call = aCall;
                [self performSegueWithIdentifier:performedSegueIdentiferAtIncall sender:self];
			}
            break;
        }
        default:
            break;
	}

    [LinphoneHelper updateApplicationBadgeNumber];
}

#pragma mark - Update UI Functions

// Update registration status IBOutlet element references
- (void)updateUIRegistrationStatus:(NSString *)registrationStatus
       withRegistrationStatusImage:(UIImage *)registrationStatusImage
               withRegisteredEmail:(NSString *)registeredEmail
{
    [sbRegistrationStateLabel setText:registrationStatus];
    [sbRegistrationStateImageView setImage:registrationStatusImage];
    [sbRegisteredEmailLabel setText:registeredEmail];
}



#pragma mark - Segue Functions

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

    if (sender == self) {
        
        // Pass selectedContact to the secure call view
        if([segue.identifier isEqualToString:performedSegueIdentiferAtIncall]){
            CallerViewController *callerViewController = (CallerViewController *)segue.destinationViewController;
            
            // This is an incoming call
            if (call && callerViewController.callType == kNone) {
                callerViewController.callType = kIncoming;
                callerViewController.incomingCall = call;
                callerViewController.contact = nil;
                
                // reset call pointer
                call = nil;
            }
        }
    }
}

@end
