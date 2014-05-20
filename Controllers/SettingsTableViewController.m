//
//  SettingsViewController.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 11/02/2014.
//
//

#import "SettingsTableViewController.h"

#import "LinphoneManager.h"
#import "Settings.h"

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

@synthesize setting;
@synthesize navigationItem;

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
    // Init status bar elements
    [super viewDidLoadWithPerformedSegueIdentifierAtIncall:@"StartSecureCallSegue"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView
                       cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    // Check the actual selection
    switch (setting)
    {
        case AutoClearCallHistory:
            if ([indexPath row] == [Settings autoClearCallHistory] - 1) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
            
        case AutoClearChatHistory:
            if ([indexPath row] == [Settings autoClearChatHistory] - 1) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Save the selected values into the Settings
    switch (setting)
    {
        case AutoClearCallHistory:
            [Settings setAutoClearCallHistory:[indexPath row] + 1];
            break;
        case AutoClearChatHistory:
            [Settings setAutoClearChatHistory:[indexPath row] + 1];
            break;
    }

    // Go back to the previous screen
    [self.navigationController popViewControllerAnimated:YES];
}

@end
