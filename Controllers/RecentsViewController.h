//
//  CallHistoryViewController.h
//  ringring.io
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

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButtonItem;
@property (weak, nonatomic) IBOutlet UITableView *recentsTableView;


- (IBAction)enterEditMode:(id)sender;

@end
