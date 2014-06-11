//
//  CallHistoryViewController.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 12/01/2014.
//
//

#import "RecentsViewController.h"
#import "RecentsTableViewCell.h"
#import "RecentContact.h"
#import "ChatViewController.h"

#import "LinphoneManager.h"
#import "LinphoneHelper.h"
#import "CallerViewController.h"
#import "AddressBookMap.h"
#import "Message.h"
#import "Settings.h"



@interface RecentsViewController () {
    NSMutableArray *recentContacts;
    NSTimer *recentsRefreshTimer;
}
@end

@implementation RecentsViewController {
    NSArray *tableData;
}

@synthesize selectedRecentContact;
@synthesize registrationStateImage;
@synthesize registrationStateLabel;
@synthesize registeredUserLabel;

@synthesize navigationItem;
@synthesize editButtonItem;
@synthesize recentsTableView;



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
    [super viewDidLoadWithRegistrationStateLabel:registrationStateLabel
                          registrationStateImage:registrationStateImage
                            registeredEmailLabel:registeredUserLabel
                performedSegueIdentifierAtIncall:@"StartSecureCallSegue"];
    
    // Init recentsContacts array
    recentContacts = [[NSMutableArray alloc] init];
    
    // Init pull down refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refreshRecentContacts:)
             forControlEvents:UIControlEventValueChanged];
    [recentsTableView addSubview:refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refreshRecents:nil];
    
    // Reset missed call log counter
    linphone_core_reset_missed_calls_count([LinphoneManager getLc]);

    // Turn off edit mode
    [recentsTableView setEditing:NO animated:NO];
    
    // Set observer - Text received listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textReceived:)
                                                 name:kLinphoneTextReceived
                                               object:nil];
    // Replace and show Edit button
    navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                      target:self
                                                                                      action:@selector(enterEditMode:)];
    
    // Init Recents Refresh Timer
    [self initRecentsRefreshTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Update application badge number
    [LinphoneHelper updateApplicationBadgeNumber];
    
    // Update badge number on Recents tab
    [self updateRecentsBadgeNumber];
    
    // Remove observer - Text received listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneTextReceived
                                                  object:nil];
    
    // Init Recents Refresh Timer
    [self stopRecentsRefreshTimer];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - User Event Functions

// User selected a row from the table view
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedRecentContact = [recentContacts objectAtIndex:indexPath.row];
    
    // Start secure call or secure chat
    switch ((RecentType)selectedRecentContact.recentType) {
        case RecentCall:
            [self performSegueWithIdentifier:@"StartSecureCallSegue" sender:self];
            break;
            
        case RecentMessage:
            [self performSegueWithIdentifier:@"StartSecureChatSegue" sender:self];
            break;
    }
}



#pragma mark - Table functions

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [recentContacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"RecentsTableCell";

    RecentsTableViewCell *cell = (RecentsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
 
    if (cell == nil) {
        cell = [[RecentsTableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:cellIdentifier];
    }
    
    RecentContact *recentContact = [recentContacts objectAtIndex:indexPath.row];

    cell.contactEmailLabel.text = recentContact.email;
    cell.contactEmailLabel.font = [UIFont systemFontOfSize:14];
    cell.contactFullNameLabel.text = recentContact.fullName;
    cell.contactImage.image = [LinphoneHelper imageAsCircle:recentContact.image];
    
    cell.startTimeLabel.text = [LinphoneHelper dateToString:recentContact.recentDate];
    
    // Customize the cell based on the recent types - Call/Message/Incoming/Outgoing/etc.
    NSString *recentTypeButtonImageName;
    switch ((RecentType)recentContact.recentType) {
        case RecentCall:
            
            // Mark contact email as red if the call is not success
            switch ((LinphoneCallStatus)recentContact.callStatus) {
                case LinphoneCallSuccess:
                    cell.contactEmailLabel.textColor = [UIColor blackColor];
                    break;
                default:
                    cell.contactEmailLabel.textColor = [UIColor redColor];
                    break;
            }
            
            // Show incoming/outgoing call icons
            switch ((LinphoneCallDir)recentContact.callDirection) {
                case LinphoneCallIncoming:
                    recentTypeButtonImageName = @"incoming_call_success.png";
                    break;
                case LinphoneCallOutgoing:
                    recentTypeButtonImageName = @"outgoing_call_success.png";
                    break;
            }
            break;
            
        // Show message icon in case of any message events
        case RecentMessage:
            cell.contactEmailLabel.textColor = [UIColor blackColor];
            
            // Set bold email label in case there is any unread message
            if (recentContact.hasUnreadMessages) {
                cell.contactEmailLabel.font = [UIFont boldSystemFontOfSize:14];
            }
            recentTypeButtonImageName = @"contacts_text.png";
            break;
    }
    
    [cell.recentTypeButton setImage:[UIImage imageNamed:recentTypeButtonImageName]
                           forState:UIControlStateNormal];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}



#pragma mark - Segue Functions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [super prepareForSegue:segue sender:sender];

    if (sender == self) {
        
        // Set the caller view as the destination segue
        if([segue.identifier isEqualToString:@"StartSecureCallSegue"]){
            CallerViewController *callerViewController = (CallerViewController *)segue.destinationViewController;
            
            // Init an outgoing call and pass the selected recent contact to the secure call view
            if (callerViewController.callType == kNone) {
                callerViewController.callType = kOutgoing;
                callerViewController.incomingCall = nil;
                callerViewController.contact = (Contact *)selectedRecentContact;
            }
        }

        // Set the chat view as the destination segue
        if([segue.identifier isEqualToString:@"StartSecureChatSegue"]){
            
            UINavigationController *navigationController = (UINavigationController *)segue.destinationViewController;
            
            NSArray *viewControllers = navigationController.viewControllers;
            ChatViewController *chatViewController = [viewControllers objectAtIndex:0];
            
            // Pass chat contact
            chatViewController.contact = (Contact *)selectedRecentContact;
        }
    }
}



#pragma mark - Call properties to string functions




#pragma mark -

- (void)refreshRecentContacts:(id)sender
{
    // Refresh address book map on pull down refresh
    if (sender) {
        [AddressBookMap reload];
        
        // Hide refresh control
        [(UIRefreshControl *)sender endRefreshing];
    }
    
    // Remove old data
    [recentContacts removeAllObjects];
    
    // Get call and message logs from address book
    const MSList *callLogList = linphone_core_get_call_logs([LinphoneManager getLc]);
    NSMutableArray *messageLogList = [Message listMessageLog];
    
    // Build recent contacts array
    recentContacts = [AddressBookMap getRecentContacts:callLogList
                                    withMessageLogList:messageLogList];
    
    // refresh UITableView with new data
    [recentsTableView reloadData];
}

- (void)deleteCallLogWithRecentContact:(RecentContact *)recentContact
{
    const MSList *callLogList = linphone_core_get_call_logs([LinphoneManager getLc]);
    
    // Get a list of emails from logs
    const MSList *logListRef = callLogList;
    while(logListRef != NULL) {
        LinphoneCallLog *callLog = (LinphoneCallLog *) logListRef->data;
        NSString *logEmail = [LinphoneHelper emailFromCallLog:callLog];
        logListRef = ms_list_next(logListRef);

        if ([logEmail isEqualToString:recentContact.email]) {
            linphone_core_remove_call_log([LinphoneManager getLc], callLog);
        }
    }
}

- (void)deleteCallLogBeforeDate:(NSDate *)date
{
    const MSList *callLogList = linphone_core_get_call_logs([LinphoneManager getLc]);
    
    // Get a list of emails from logs
    const MSList *logListRef = callLogList;
    while(logListRef != NULL) {
        LinphoneCallLog *callLog = (LinphoneCallLog *) logListRef->data;
        
        NSDate *callStartDate = [NSDate dateWithTimeIntervalSince1970:linphone_call_log_get_start_date(callLog)];
        logListRef = ms_list_next(logListRef);
        
        // Remove call logs before date
        if ([callStartDate compare:date] == NSOrderedAscending) {
            linphone_core_remove_call_log([LinphoneManager getLc], callLog);
        }
    }
}

- (void)deleteLogsAuto
{
    NSDate *currentDate = [NSDate date];
    NSDate *firstLogDate = [currentDate dateByAddingTimeInterval:
                            [Settings clearIntervalToTimeInterval:
                             [Settings autoClearCallHistory]] * -1];

    if ([Settings autoClearCallHistory]) {
        [self deleteCallLogBeforeDate:firstLogDate];

    }
    
    if ([Settings autoClearChatHistory]) {
        [Message deleteMessagesBeforeDate:firstLogDate];
    }
}

- (void)deleteLogsWithRecentContact:(RecentContact *)recentContact
{
    // Delete call log or message log
    switch ((RecentType)recentContact.recentType) {
        case RecentCall:
            [self deleteCallLogWithRecentContact:recentContact];
            break;
            
        case RecentMessage:
            [Message deleteMessagesWithContactEmail:recentContact.email];
            break;
    }
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

- (void)textReceived:(id)sender
{
    // Auto delete old logs
    [self deleteLogsAuto];
    
    // Refresh recent contacts list
    [self refreshRecentContacts:nil];

    // Update badge numbers
    [self updateRecentsBadgeNumber];
}

    - (IBAction)enterEditMode:(id)sender
{
    // Set edit mode and replace and show Done button
    if (![recentsTableView isEditing]) {
        // Turn on edit mode
        [recentsTableView setEditing:YES animated:YES];
        
        // Replace and show Done button
        navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(enterEditMode:)];
    }
    // Unset edit mode and replace and show Edit button
    else {
        // Turn off edit mode
        [recentsTableView setEditing:NO animated:YES];
        
        // Replace and show Edit button
        navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                          target:self
                                                                                          action:@selector(enterEditMode:)];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Delete recents
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        RecentContact *recentContact = [recentContacts objectAtIndex:indexPath.row];
        
        // Delete entries from call and message logs
        [self deleteLogsWithRecentContact:recentContact];
        
        // Delete the row from the data source
        [recentContacts removeObjectAtIndex:indexPath.row];

        // Animate the deletion
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        // Refresh recent contacts list
        [self refreshRecentContacts:nil];
        
        // Update application badge number
        [LinphoneHelper updateApplicationBadgeNumber];
        
        // Update recents badge number
        [self updateRecentsBadgeNumber];
    }
}

- (void)refreshRecents:(NSTimer *) aTimer
{
    // Update application badge number
    [LinphoneHelper updateApplicationBadgeNumber];
    
    // Update badge number on Recents tab
    [self updateRecentsBadgeNumber];
    
    // Auto delete old logs
    [self deleteLogsAuto];
    
    // Refresh recent contacts list
    [self refreshRecentContacts:nil];
}

#pragma mark - Recents Refresh Timer Functions

- (void)initRecentsRefreshTimer {
    recentsRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                           target:self
                                                         selector:@selector(refreshRecents:)
                                                         userInfo:nil
                                                          repeats:TRUE];
}

- (void)stopRecentsRefreshTimer {
    
    if (recentsRefreshTimer) {
        [recentsRefreshTimer invalidate];
        recentsRefreshTimer = nil;
    }
}

@end
