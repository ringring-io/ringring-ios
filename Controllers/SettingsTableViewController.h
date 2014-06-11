//
//  SettingsViewController.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 11/02/2014.
//
//

#import "UITableViewControllerWithLinphoneListener.h"
#import "Settings.h"

@interface SettingsTableViewController : UITableViewControllerWithLinphoneListener

@property (nonatomic) Setting setting;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

@end
