//
//  WizardActivateViewController.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 10/01/2014.
//
//

#import <UIKit/UIKit.h>

#import "UIViewControllerWithStatusBar.h"

@interface WizardActivateViewController : UIViewController

@property (nonatomic, retain) UITextField *userEmailTextField;
@property (strong, nonatomic) IBOutlet UITextField *activationCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton *activateButton;

- (IBAction)activateButtonTapped:(UIButton *)sender;
- (IBAction)textFieldReturn:(id)sender;

@end
