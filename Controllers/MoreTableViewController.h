//
//  SettingsViewController.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 11/02/2014.
//
//

#import "UITableViewControllerWithLinphoneListener.h"

@interface MoreTableViewController : UITableViewControllerWithLinphoneListener


@property (weak, nonatomic) IBOutlet UISwitch *autoClearCallHistorySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *autoClearChatHistorySwitch;

@property (weak, nonatomic) IBOutlet UITableViewCell *clearCallsIntervalCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *clearChatsIntervalCell;

@end
