//
//  ContactListViewController.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 12/01/2014.
//
//

#import <UIKit/UIKit.h>

#import "WizardActivateViewController.h"
#import "UIViewControllerWithStatusBar.h"
#import "Contact.h"

@interface ContactsViewController : UIViewControllerWithStatusBar <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) Contact* selectedContact;

@property (nonatomic, retain) IBOutlet UILabel *registrationStateLabel;
@property (nonatomic, retain) IBOutlet UIImageView *registrationStateImage;
@property (nonatomic, retain) IBOutlet UILabel *registeredUserLabel;

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addContactButtonItem;

@property (nonatomic, weak) IBOutlet UISearchBar *contactPersonSearchBar;

@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;

- (IBAction)addContact:(id)sender;

- (IBAction)textfieldReturn:(UITextField *)sender;

@property (strong, nonatomic) IBOutlet UISearchDisplayController *contactsSearchDisplayController;

@end
