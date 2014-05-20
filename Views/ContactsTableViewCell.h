//
//  ContactListTableViewCell.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 12/01/2014.
//
//

#import <UIKit/UIKit.h>
#import "ContactsViewController.h"

@interface ContactsTableViewCell : UITableViewCell

@property (nonatomic, weak) ContactsViewController *contactsViewController;
@property (nonatomic, strong) Contact* contact;

@property (nonatomic, strong) IBOutlet UIImageView *contactImage;
@property (nonatomic, strong) IBOutlet UIImageView *statusImage;
@property (nonatomic, strong) IBOutlet UILabel *contactEmailLabel;
@property (nonatomic, strong) IBOutlet UILabel *contactFullNameLabel;
@property (nonatomic, strong) IBOutlet UIButton *sendMessageButton;

- (IBAction)sendMessageButtonTapped:(id)sender;

- (void)refresh;

@end
