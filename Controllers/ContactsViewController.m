//
//  ContactListViewController.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 12/01/2014.
//
//

#import "ContactsViewController.h"
#import "ContactsTableViewCell.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import "Contact.h"
#import "LinphoneManager.h"
#import "LinphoneHelper.h"
#import "CallerViewController.h"
#import "ChatViewController.h"
#import "AddressBookMap.h"

#import "SVProgressHUD.h"
#import "RestKit/RestKit.h"

#import "Status.h"
#import "User.h"



@interface ContactsViewController () <ABNewPersonViewControllerDelegate>
{
    NSMutableArray *contacts;
    NSMutableArray *filteredContacts;
}
@end



@implementation ContactsViewController {
    int alertViewId;
    NSArray *searchResults;
}

@synthesize navigationItem;
@synthesize addContactButtonItem;
@synthesize contactPersonSearchBar;
@synthesize selectedContact;
@synthesize registrationStateImage;
@synthesize registrationStateLabel;
@synthesize registeredUserLabel;
@synthesize contactsTableView;
@synthesize contactsSearchDisplayController;



#pragma mark - Initialization Functions

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
    // Init status bar elements
    [super viewDidLoadWithRegistrationStateLabel:registrationStateLabel
                          registrationStateImage:registrationStateImage
                             registeredEmailLabel:registeredUserLabel
                performedSegueIdentifierAtIncall:@"StartSecureCallSegue"];
    
    // Init recentsContacts array
    contacts = nil;
    contacts = [[NSMutableArray alloc] init];
    
    // Initialize the filteredContactPersons with a capacity equal to the contactPersons' capacity
    filteredContacts = nil;
    filteredContacts = [[NSMutableArray alloc] init];
    
    // Init pull down refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refreshContacts:)
             forControlEvents:UIControlEventValueChanged];    
    [contactsTableView addSubview:refreshControl];
}

-(void)viewWillLayoutSubviews
{
    if(self.searchDisplayController.isActive)
    {
        [UIView animateWithDuration:0.001 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self.navigationController setNavigationBarHidden:NO animated:NO];
        }completion:nil];
    }
    [super viewWillLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update badge number on Recents tab
    [self updateRecentsBadgeNumber];
    
    // Refresh contacts list
    [self refreshContacts:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove observer - Text field change listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:nil];
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        selectedContact = [filteredContacts objectAtIndex:indexPath.row];
    }
    else {
        selectedContact = [contacts objectAtIndex:indexPath.row];
    }

    // Start secure call
    [self startSecureCall:selectedContact forIndexPath:indexPath];
}

// Add new contact
- (IBAction)addContact:(id)sender {
    ABNewPersonViewController *picker = [[ABNewPersonViewController alloc] init];
    picker.newPersonViewDelegate = self;
    
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:picker];
    [self presentViewController:navigation animated:YES completion:nil];
}

// Dismisses the new-person view controller.
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{
    // Reload address book map
    [AddressBookMap reload];
    
    // Refresh contacts list
    [self refreshContacts:nil];

    // Dismiss new person view controller
	[self dismissViewControllerAnimated:YES completion:NULL];
}

// Hide keyboard when clicked on the return button
- (IBAction)textfieldReturn:(UITextField *)sender {
    [sender resignFirstResponder];
}

- (void)loadStatusesForOnscreenRows:(UIScrollView *)scrollView
{
    // Select contact list
    NSMutableArray *activeContacts;
    if (scrollView == self.searchDisplayController.searchResultsTableView) {
        activeContacts = filteredContacts;
    } else {
        activeContacts = contacts;
    }

    // Load statuses only if the contact list is not empty
    if ([activeContacts count] > 0)
    {
        NSArray *visiblePaths = [self.contactsTableView indexPathsForVisibleRows];
        NSMutableDictionary *emailWithIndexPathDict = [[NSMutableDictionary alloc] init];
        
        // Foreach on the visible index paths and create a list of emails what needs to be refreshed
        for (NSIndexPath *indexPath in visiblePaths)
        {
            // Don't process empty rows
            if (indexPath.row <= activeContacts.count - 1) {
                Contact *contact = [activeContacts objectAtIndex:indexPath.row];

                // Create a list of emails where the status is more than two minutes old
                NSDate *statusRefreshBound = [[NSDate date] dateByAddingTimeInterval:-120];
                if (contact.statusRefreshedAt == nil || [contact.statusRefreshedAt compare:statusRefreshBound] == NSOrderedAscending) {
                    [emailWithIndexPathDict setObject:indexPath forKey:contact.email];
                }
            
                // Update status refreshed date
                contact.statusRefreshedAt = [NSDate date];
            }
        }
        
        // Send request to the server API to get the current statuses of the users
        if ([emailWithIndexPathDict count] > 0) {
            [self startUserStatusesDownload:emailWithIndexPathDict];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self loadStatusesForOnscreenRows:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadStatusesForOnscreenRows:scrollView];
}


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    // Replace and show Call button
    navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Call", nil)
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(callManualNumber:)];
    
    // Check current text and enable/disable call button
    if ([LinphoneHelper isValidEmail:searchBar.text]) {
        [navigationItem.rightBarButtonItem setEnabled:TRUE];
    }
    else {
        [navigationItem.rightBarButtonItem setEnabled:FALSE];
    }
}

- (void)searchBar:(UISearchBar *)contactPersonSearchBar textDidChange:(NSString *)searchText
{
    // Check new text and enable/disable call button
    if ([LinphoneHelper isValidEmail:searchText]) {
        [navigationItem.rightBarButtonItem setEnabled:TRUE];
    }
    else {
        [navigationItem.rightBarButtonItem setEnabled:FALSE];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // Replace and show Add Contact button
    navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                          target:self
                                                                                          action:@selector(addContact:)];
}

// User selected a row from the table view
- (void)callManualNumber:(id)sender
{
    selectedContact = [[Contact alloc] initWithDefault:contactPersonSearchBar.text];

    // Start secure call
    [self startSecureCall:selectedContact forIndexPath:nil];
}

// Used added new contact on the caller view - Refresh contact list
- (void)callerViewDidAddContact:(CallerViewController *)callerViewController
{
    // Reload address book map
    [AddressBookMap reload];
    
    // Refresh contacts list
    [self refreshContacts:nil];
}

// Send invitation confirmation
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Send invitation
    if (buttonIndex == 1) {
        [self showLoader];
        [self invite:selectedContact.email];
    }
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



#pragma mark - Searchbar Functions

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Check to see whether the normal table or search results table is being displayed and return the count from the appropriate array
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [filteredContacts count];
    } else {
        return [contacts count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ContactsTableCell";
    ContactsTableViewCell *cell = (ContactsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[ContactsTableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:cellIdentifier];
    }
    
    // Check to see whether the normal table or search results table is being displayed and set the ContactPerson object from the appropriate array
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.contact = [filteredContacts objectAtIndex:indexPath.row];
    }
    else {
        cell.contact = [contacts objectAtIndex:indexPath.row];
    }
    
    cell.contactsViewController = self;
    [cell refresh];
    
    return cell;
}

// Filtering on contactPersons
- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [filteredContacts removeAllObjects];
    
    // Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.email contains[cd] %@ OR SELF.fullName contains[cd] %@", searchText, searchText];
    filteredContacts = [NSMutableArray arrayWithArray:[contacts filteredArrayUsingPredicate:predicate]];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    // Send request to get the statuses of the visible contacts
    [self loadStatusesForOnscreenRows:self.searchDisplayController.searchResultsTableView];

    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

// Return filter result cell height
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}



#pragma mark - Segue Functions

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [super prepareForSegue:segue sender:sender];

    if (sender == self) {
        
        // Set the caller view as the destination segue
        if([segue.identifier isEqualToString:@"StartSecureCallSegue"]){
            CallerViewController *callerViewController = (CallerViewController *)segue.destinationViewController;
            callerViewController.delegate = self;
            
            // Init an outgoing call and pass the selected contact to the secure call view
            if (callerViewController.callType == kNone) {
                callerViewController.callType = kOutgoing;
                callerViewController.incomingCall = nil;
                callerViewController.contact = selectedContact;
            }
        }
        
        // Set the chat view as the destination segue
        if([segue.identifier isEqualToString:@"StartSecureChatSegue"]){
            
            UINavigationController *navigationController = (UINavigationController *)segue.destinationViewController;
            
            NSArray *viewControllers = navigationController.viewControllers;
            ChatViewController *chatViewController = [viewControllers objectAtIndex:0];
            
            // Pass chat contact
            chatViewController.contact = selectedContact;
        }
    }
}



#pragma mark -

- (void)refreshContacts:(id)sender
{
    // Refresh address book map on pull down refresh
    if (sender) {
        // Reload address book map
        [AddressBookMap reload];
        
        // Hide refresh control
        [(UIRefreshControl *)sender endRefreshing];
    }
    
    // Remove old data
    [contacts removeAllObjects];
    
    //NSMutableArray *myContacts = [Contact listMyContacts];
    
    // Get all contact from address book
    contacts = [AddressBookMap getAllContacts];
    
    // Refresh contacts with unread messages
    [self refreshContactsWithUnreadMessages:YES];

    // Send request to get the statuses of the visible contacts
    [self loadStatusesForOnscreenRows:contactsTableView];

    // Refresh UITableView with new data
    [contactsTableView reloadData];
}

- (void)refreshContactsWithUnreadMessages:(BOOL)reloadTableData
{
    NSMutableArray *messageLogList = [Message listMessageLog];

    // Find every contact who has unread messages
    for (Message *message in messageLogList) {
        if (message.hasUnreadMessages) {
            
            // Update contact has unread messages flag to YES
            for (Contact *contact in contacts) {
                if ([contact.email isEqualToString:message.email]) {
                    contact.hasUnreadMessages = YES;
                    break;
                }
            }
        }
    }
    
    // Refresh contacts table if required
    if (reloadTableData)
        [contactsTableView reloadData];
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

// Get the status a contact by RESTful API call
- (void)startSecureCall:(Contact *)contact forIndexPath:(NSIndexPath *)indexPath{
    
    // Show loader animation
    [self showLoader];
    
    // Send user status details request
    [[RKObjectManager sharedManager] getObject:nil
                                          path:[NSString stringWithFormat:@"/v2/user/%@", contact.email]
                                    parameters:nil
                                       success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                           
        // Hide the loader animation
        [self dismissLoader];
        
        // Get results: query results and user
        Status *status = [mappingResult.dictionary objectForKey:@""];
        User *user = [mappingResult.dictionary objectForKey:@"user"];
                                           
        // Check result
        if (status.success) {

            // Update the user statuses
            contact.isActivated = user.isActivated;
            contact.isLoggedIn = user.isLoggedIn;
            contact.statusRefreshedAt = [NSDate date];
            
            // Update contactlist cell
            if(indexPath != nil) {
                ContactsTableViewCell *cell = (ContactsTableViewCell *)[self.contactsTableView cellForRowAtIndexPath:indexPath];
                cell.contact = contact;
                [cell refresh];
            }
            
            // The contact is activated
            if (contact.isActivated) {

                // The contact is activated and logged in. Start the call
                if (contact.isLoggedIn) {
                    [self performSegueWithIdentifier:@"StartSecureCallSegue" sender:self];
                }
                
                // The contact is activated but not logged in
                else {
                    UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Call failed", nil)
                                                                    message:NSLocalizedString(@"This user is not available at the moment", nil)
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                          otherButtonTitles:nil];
                    [errorView show];
                }
            }
            
            // The contact is not activated
            else {
                UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Call failed", nil)
                                                                message:NSLocalizedString(@"This user is not registered at Zirgoo", nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                                      otherButtonTitles:nil];
                 [errorView show];
            }
        }
                                           
        // Any other non-success message
        else if ([status.status isEqualToString:@"USER_NOT_FOUND"]) {
            UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"This email is not registered", nil)
                                                                message:NSLocalizedString(@"Do you want to invite this person to use Zirgoo?", nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"No",nil)
                                                      otherButtonTitles:NSLocalizedString(@"Yes",nil), nil];
            [errorView show];
        }
                                           
        // Any other non-success message
        else {
            UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                                message:NSLocalizedString(status.status, nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                      otherButtonTitles:nil,nil];
            [errorView show];
        }

                                           
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
        // Hide the loader animation
        [self dismissLoader];
        
        // Set default error message
        NSString *errorMessage = @"Unknown error occured";
        
        // Check internet connection error
        if([error code] == -1009) {
            errorMessage = [error localizedDescription];
        } else {
            errorMessage = [NSString stringWithFormat:@"Internal communication error. (Code: %ld)", (long)[error code]];
        }
        
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                            message:NSLocalizedString(errorMessage, nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];

    }];
}

// Get the statuses of a list of contacts by RESTful API call
- (void)startUserStatusesDownload:(NSMutableDictionary *)emailWithIndexPathDict {
    
    // Set request and parameters
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [emailWithIndexPathDict allKeys], @"emails",
                                   nil];
    
    // Send Register email request
    [[RKObjectManager sharedManager] postObject:nil
                                           path:@"v2/user/list"
                                     parameters:params
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                            
        // Get results: query result and user list
        Status *status = [mappingResult.dictionary objectForKey:@""];
        NSArray *users = [mappingResult.dictionary objectForKey:@"users"];
                                            
        // Check result
        if (status) {
            
            // Go to the activate email screen if the response is success
            if (status.success) {
                for (User *user in users) {

                    for (Contact *contact in contacts) {
                        if ([contact.email isEqualToString:user.email]) {
                            
                            // Update contact attributes
                            contact.isActivated = user.isActivated;
                            contact.isLoggedIn = user.isLoggedIn;
                            contact.statusRefreshedAt = [NSDate date];
                            
                            // Update contactlist cell
                            NSIndexPath *indexPath = [emailWithIndexPathDict objectForKey:user.email];

                            if (indexPath) {
                                ContactsTableViewCell *cell = (ContactsTableViewCell *)[self.contactsTableView cellForRowAtIndexPath:indexPath];
                                cell.contact = contact;
                                                                
                                [cell refresh];
                            }
                            
                            break;
                        }
                    }
                }
            }
        }
                                            
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
    }];
}

// Get the statuses of a list of contacts by RESTful API call
- (void)invite:(NSString *)email {
    
    // Set request and parameters
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [LinphoneHelper registeredEmail], @"from_email",
                                   email, @"to_email",
                                   nil];
     
    // Send Register email request
    [[RKObjectManager sharedManager] postObject:nil path:[NSString stringWithFormat:@"/v2/user/%@/invite", email]
                                    parameters:params
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        // Hide the loader animation
        [self dismissLoader];
          
        // Get results: query result and user list
        Status *status = [mappingResult.dictionary objectForKey:@""];
        
        if (status.success) {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Great",nil)
                                                                message:NSLocalizedString(@"The invitation will be sent to your contact shortly, provided that no other invitation has not been sent", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Dismiss",nil)
                                                      otherButtonTitles:nil,nil];
            [alertView show];
        }
        else {
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fail",nil)
                                                                message:NSLocalizedString(@"Could not send the invitation this time. Try again later", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Dismiss",nil)
                                                      otherButtonTitles:nil,nil];
            [alertView show];
        }

     } failure:^(RKObjectRequestOperation *operation, NSError *error) {
         
         // Hide the loader animation
         [self dismissLoader];
         
         UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fail",nil)
                                                             message:NSLocalizedString(@"Could not send the invitation this time. Try again later", nil)
                                                            delegate:nil
                                                   cancelButtonTitle:NSLocalizedString(@"Dismiss",nil)
                                                   otherButtonTitles:nil,nil];
         [alertView show];
     }];
}

@end
