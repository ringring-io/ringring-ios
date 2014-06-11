//
//  StatusBarViewController.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 15/01/2014.
//
//

#import <UIKit/UIKit.h>

@interface UIViewControllerWithStatusBar : UIViewController;

- (id)viewDidLoadWithRegistrationStateLabel:(UILabel *)registrationStateLabel
                     registrationStateImage:(UIImageView *)registrationStateImage
                        registeredEmailLabel:(UILabel *)registeredUserLabel
           performedSegueIdentifierAtIncall:(NSString *)performedSegueIdentifierAtIncall;

- (void)registrationUpdateOnStatusBar: (NSNotification*) notif;
- (void)callUpdateOnStatusBar: (NSNotification*) notif;

@end