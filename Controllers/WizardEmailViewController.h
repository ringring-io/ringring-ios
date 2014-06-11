//
//  WizardEmailViewController.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 10/01/2014.
//
//

#import <UIKit/UIKit.h>

@interface WizardEmailViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *userEmailTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;

- (IBAction)registerButtonTapped:(UIButton *)sender;
- (IBAction)textFieldReturn:(id)sender;

@end
