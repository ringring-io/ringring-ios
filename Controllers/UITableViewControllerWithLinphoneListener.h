//
//  UITableViewControllerWithLinphoneListener.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 15/02/2014.
//
//

#import <UIKit/UIKit.h>

#import "StaticDataTableViewController.h"

@interface UITableViewControllerWithLinphoneListener : StaticDataTableViewController

- (id)viewDidLoadWithPerformedSegueIdentifierAtIncall:(NSString *)performedSegueIdentifierAtIncall;

@end
