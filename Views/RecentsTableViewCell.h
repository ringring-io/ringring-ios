//
//  CallHistoryTableViewCell.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 12/01/2014.
//
//

#import <UIKit/UIKit.h>
#import "ContactsViewController.h"

@interface RecentsTableViewCell : UITableViewCell

@property (nonatomic, weak) ContactsViewController *contactsViewController;
@property (nonatomic, strong) Contact* contact;

@property (nonatomic, weak) IBOutlet UIImageView *contactImage;
@property (nonatomic, weak) IBOutlet UILabel *contactEmailLabel;
@property (nonatomic, strong) IBOutlet UILabel *contactFullNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *recentTypeButton;

@end
