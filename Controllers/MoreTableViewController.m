//
//  SettingsViewController.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 11/02/2014.
//
//

#import "MoreTableViewController.h"

#import "LinphoneManager.h"
#import "LinphoneHelper.h"
#import "Settings.h"
#import "SettingsTableViewController.h"
#import "SVProgressHUD.h"

@interface MoreTableViewController () {
    BOOL isUnregisterSent;
    NSTimer *logoutTimeoutTimer;
}
@end

@implementation MoreTableViewController

@synthesize autoClearCallHistorySwitch;
@synthesize autoClearChatHistorySwitch;
@synthesize clearCallsIntervalCell;
@synthesize clearChatsIntervalCell;



#pragma mark - Initialization Functions

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    // Init call listener
    [super viewDidLoadWithPerformedSegueIdentifierAtIncall:@"StartSecureCallSegue"];
    
    // Switch status change listeners
    [autoClearCallHistorySwitch addTarget:self
                                   action:@selector(switchTapped:)
                         forControlEvents:UIControlEventValueChanged];
    
    [autoClearChatHistorySwitch addTarget:self
                                   action:@selector(switchTapped:)
                         forControlEvents:UIControlEventValueChanged];
    
    // Customize animations
    [self setReloadTableViewRowAnimation:UITableViewRowAnimationMiddle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    // Update badge number on Recents tab
    [self updateRecentsBadgeNumber];

    // Set observer - Registration update listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdate:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    // Set observer - Text received listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textReceived:)
                                                 name:kLinphoneTextReceived
                                               object:nil];
    
    // Refresh available settings list
    [self refreshAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove observer - Registration update listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneRegistrationUpdate
                                                  object:nil];
    
    // Remove observer - Text received listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:kLinphoneTextReceived
                                               object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Update Event Functions

- (void)registrationUpdate: (NSNotification*) notif {
    LinphoneProxyConfig *proxyCfg = [[notif.userInfo objectForKey: @"cfg"] pointerValue];
    LinphoneRegistrationState state = linphone_proxy_config_get_state(proxyCfg);
    
    switch (state) {
            
        // Unregistered successfully from the server
        case LinphoneRegistrationCleared:
            if(isUnregisterSent) {
                [self logout];
            }
            break;
            
        case LinphoneRegistrationNone:
        case LinphoneRegistrationFailed:
        case LinphoneRegistrationOk:
        case LinphoneRegistrationProgress:
            break;
    }
}

- (void)textReceived:(id)sender
{
    [self updateRecentsBadgeNumber];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Logout selected
    if ([indexPath section] == 2 && [indexPath row] == 0) {
        UIAlertView* confirmLogoutView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm", nil)
                                                                    message:NSLocalizedString(@"Do you want to logout?", nil)
                                                                   delegate:self
                                                          cancelButtonTitle:@"No"
                                                          otherButtonTitles:@"Yes", nil];
        
        [confirmLogoutView show];
    }
}

// Logout confirmation
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Clear user credentials and go back to the registration screen
    if (buttonIndex == 1)
    {
        isUnregisterSent = true;
        [self showLoader];

        // Ignore every user event during the logout process
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        
        // Force logout if no response to the unregister request
        // Will be unregistered automatically after 10 minutes by the server
        logoutTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f
                                                     target:self
                                                   selector:@selector(forceLogout:)
                                                   userInfo:nil
                                                    repeats:FALSE];
        // Send unregister request to the server
        [LinphoneHelper unregisterSip];
    }
}

- (void)forceLogout:(NSTimer *) aTimer
{
    [self logout];
}

- (void)logout
{
    [LinphoneHelper clearProxyConfig];

    [self dismissLoader];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchTapped:(id)sender {
    // Save new settings
    [Settings setAutoClearCallHistoryEnabled:[autoClearCallHistorySwitch isOn]];
    [Settings setAutoClearChatHistoryEnabled:[autoClearChatHistorySwitch isOn]];
    
    // Refresh available settings list
    [self refreshAnimated:YES];
    
}

#pragma mark - UI Functions

// Show loading anim
- (void)showLoader
{
    [SVProgressHUD show];
}

// Remove loading anim
- (void)dismissLoader
{
    [SVProgressHUD dismiss];
}

- (void)refreshAnimated:(BOOL)animated {
    
    // Set interval detail texts to the actual values
    clearCallsIntervalCell.detailTextLabel.text = [Settings clearIntervalToString:[Settings autoClearCallHistory]];
    clearChatsIntervalCell.detailTextLabel.text = [Settings clearIntervalToString:[Settings autoClearChatHistory]];
    
    // Show or hide elements based on the current user settings
    if ([Settings isAutoClearCallHistoryEnabled]) {
        [autoClearCallHistorySwitch setOn:YES];
        [self cell:clearCallsIntervalCell setHidden:NO];
    }
    else {
        [autoClearCallHistorySwitch setOn:NO];
        [self cell:clearCallsIntervalCell setHidden:YES];
    }

    if ([Settings isAutoClearChatHistoryEnabled]) {
        [autoClearChatHistorySwitch setOn:YES];
        [self cell:clearChatsIntervalCell setHidden:NO];
    }
    else {
        [autoClearChatHistorySwitch setOn:NO];
        [self cell:clearChatsIntervalCell setHidden:YES];
    }
    
    // Refresh on screen
    [self reloadDataAnimated:animated];
    
}

- (void)updateRecentsBadgeNumber {
    long count = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    
    UITabBarItem *tbi = (UITabBarItem *)[self.tabBarController.tabBar.items objectAtIndex:1];
    if (count > 0) {
        [tbi setBadgeValue:[NSString stringWithFormat:@"%ld", count]];
    }
    else {
        [tbi setBadgeValue:nil];
    }
}

#pragma mark - Segue Functions

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [super prepareForSegue:segue sender:sender];
    
    // Set the header on the destination settings screen according to the selected option
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        
        // Call history settings selected
        if([segue.identifier isEqualToString:@"CallSettingsSegue"]){
            SettingsTableViewController *settingsTableViewController = (SettingsTableViewController *)segue.destinationViewController;
   
            // Set setting and table header
            settingsTableViewController.setting = AutoClearCallHistory;
            [settingsTableViewController.navigationItem setTitle:NSLocalizedString(@"Call Settings", nil)];
        }
        
        // Chat history settings selected
        if([segue.identifier isEqualToString:@"ChatSettingsSegue"]){
            SettingsTableViewController *settingsTableViewController = (SettingsTableViewController *)segue.destinationViewController;
            
            // Set setting and table header
            settingsTableViewController.setting = AutoClearChatHistory;
            [settingsTableViewController.navigationItem setTitle:NSLocalizedString(@"Chat Settings", nil)];
        }
    }
}

@end
