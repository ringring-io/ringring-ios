//
//  UITableViewControllerWithLinphoneListener.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 15/02/2014.
//
//

#import "UITableViewControllerWithLinphoneListener.h"
#import "LinphoneManager.h"
#import "CallerViewController.h"
#import "LinphoneHelper.h"

@interface UITableViewControllerWithLinphoneListener () {
    NSString *performedSegueIdentiferAtIncall;
    
    LinphoneCall *call;
}

@end

@implementation UITableViewControllerWithLinphoneListener



#pragma mark - Initialization Functions

// Init status bar UI elements
- (id)viewDidLoadWithPerformedSegueIdentifierAtIncall:(NSString *)performedSegueIdentifierAtIncall
{
    [super viewDidLoad];
    
    performedSegueIdentiferAtIncall = performedSegueIdentifierAtIncall;
    
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
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
    
    // Set observer - Call update listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdate:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
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

// Call observer actions
- (void)callUpdate:(NSNotification*)notif {
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
