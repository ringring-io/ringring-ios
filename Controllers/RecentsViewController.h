//
//  CallHistoryViewController.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 12/01/2014.
//
//

#import <UIKit/UIKit.h>

#import "UIViewControllerWithStatusBar.h"
#import "RecentContact.h"

@interface RecentsViewController : UIViewControllerWithStatusBar <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) RecentContact* selectedRecentContact;

@property (nonatomic, retain) IBOutlet UIImageView *registrationStateImage;
@property (nonatomic, retain) IBOutlet UILabel *registrationStateLabel;
@property (nonatomic, retain) IBOutlet UILabel *registeredUserLabel;

@property (weak, nonatomic) IBOutlet UITableView *recentsTableView;

@end
