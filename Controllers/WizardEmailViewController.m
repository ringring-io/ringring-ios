//
//  WizardEmailViewController.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 10/01/2014.
//
//

#import "WizardEmailViewController.h"
#import "SVProgressHUD.h"

#import "WizardActivateViewController.h"
#import "LinphoneHelper.h"

#import "RestKit/RestKit.h"
#import "MappingProvider.h"
#import "Status.h"
#import "User.h"
#import "Contact.h"

@interface WizardEmailViewController ()

@end



@implementation WizardEmailViewController

@synthesize userEmailTextField;
@synthesize registerButton;



#pragma mark - Initialisers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



#pragma mark - Lifecycle Functions

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated
{
    // Dismiss wizard screen if user account is already set up
    if ([LinphoneHelper isRegistered]) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Update Event Functions

// No Update Events



#pragma mark - User Event Functions

// Hide keyboard when clicked anywhere out of the textbox
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([userEmailTextField isFirstResponder] && [touch view] != userEmailTextField) {
        [userEmailTextField resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

// Hide keyboard when clicked on the return button
-(IBAction)textFieldReturn:(id)sender
{
    [sender resignFirstResponder];
}

// Register button tapped
- (IBAction)registerButtonTapped:(UIButton *)sender {
    NSMutableString *errors = [NSMutableString string];
    
    if (![LinphoneHelper isValidEmail:userEmailTextField.text]) {
        [errors appendString:NSLocalizedString(@"INVALID_EMAIL", nil)];
    }
    
    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CHECK_ERRORS",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"CONTINUE",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
    } else {
        [self showLoader];
        [self registerEmail:userEmailTextField.text];
    }
}

// Activation renew confirmation
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Request for new activation code
    if (buttonIndex == 1) {
        [self showLoader];
        [self renewActivationCode:userEmailTextField.text];
    }
}



#pragma mark - UI Functions

// Show loading anim
- (void)showLoader
{
    userEmailTextField.enabled = NO;
    registerButton.enabled = NO;

    [SVProgressHUD show];
}

// Remove loading anim
- (void)dismissLoader
{
    userEmailTextField.enabled = YES;
    registerButton.enabled = YES;

    [SVProgressHUD dismiss];
}



#pragma mark - Segue Functions

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    WizardActivateViewController *wizardActivationViewController = segue.destinationViewController;
    wizardActivationViewController.userEmailTextField = userEmailTextField;
}



#pragma mark - API Webservice Client Functions

// Send registration request
- (void)registerEmail:(NSString*)email {

    // Set request and parameters
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   email, @"email",
                                   nil];

    // Send Register email request
    [[RKObjectManager sharedManager] postObject:nil
                                           path:@"v2/user"
                                     parameters:params
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {

        // Hide the loader animation
        [self dismissLoader];

        // Get results: query results and user
        Status *status = [mappingResult.dictionary objectForKey:@""];
        
        // Check result
        if (status) {
            
            // Go to the activate email screen if the response is success
            if (status.success) {
                [self performSegueWithIdentifier:@"ActivateEmailSegue" sender:self];
            }
            
            // Catch email is already registered error
            else if ([status.status isEqualToString:@"EMAIL_ALREADY_REGISTERED"]) {
                    // Popup confirmation for validation code email
                    UIAlertView* userExistsView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EMAIL_ALREADY_REGISTERED", nil)
                                                                             message:NSLocalizedString(@"DO_YOU_WANT_NEW_ACTIVATION_CODE", nil)
                                                                            delegate:self
                                                                   cancelButtonTitle:NSLocalizedString(@"NO", nil)
                                                                   otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
                    [userExistsView show];
            }
            
            // Any other non-success message
            else {
                UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR",nil)
                                                                        message:NSLocalizedString(status.status, nil)
                                                                       delegate:nil
                                                              cancelButtonTitle:NSLocalizedString(@"CONTINUE",nil)
                                                              otherButtonTitles:nil,nil];
                    [errorView show];
            }
        }
        
        // The response message is not valid
        else {
            UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR",nil)
                                                                message:NSLocalizedString(@"EMPTY_RESPONSE", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"CONTINUE",nil)
                                                      otherButtonTitles:nil,nil];
            [errorView show];
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
        // Hide the loader animation
        [self dismissLoader];

        // Set default error message
        NSString *errorMessage = @"Unknown error occured";
        
        // Check internet connection error
        if([error code] == -1009) {
            errorMessage = [error localizedDescription];
        } else {
            errorMessage = [NSString stringWithFormat:@"Internal communication error. %@ (Code: %ld)", [error localizedDescription], (long)[error code]];
        }
        
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR",nil)
                                                            message:NSLocalizedString(errorMessage, nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"CONTINUE",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
    }];
}

// Send Activation code renewal request
- (void)renewActivationCode:(NSString*)email {

    // Send Register email request
    [[RKObjectManager sharedManager] getObject:nil
                                          path:[NSString stringWithFormat:@"/v2/user/%@/renewactivationcode", email]
                                    parameters:nil
                                       success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {

        // Hide the loader animation
        [self dismissLoader];

        // Get results: query results and user
        Status *status = [mappingResult.dictionary objectForKey:@""];

        // Go to the activate email screen if the response is success
        if (status && status.success) {
            [self performSegueWithIdentifier:@"ActivateEmailSegue" sender:self];
        }
        
        // Otherwise show an error message
        else {
            UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR",nil)
                                                                message:NSLocalizedString(status.status, nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"CONTINUE",nil)
                                                      otherButtonTitles:nil,nil];
            [errorView show];
        }
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
        // Hide the loader animation
        [self dismissLoader];
        
        // Set default error message
        NSString *errorMessage = @"Unknown error occured";

        // Check internet connection error
        if([error code] == -1009) {
            errorMessage = [error localizedDescription];
        } else {
            errorMessage = [NSString stringWithFormat:NSLocalizedString(@"INTERNAL_COMMUNICATION_ERROR", nil), (long)[error code]];
        }
        
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR",nil)
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"CONTINUE",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
    }];
}

@end
