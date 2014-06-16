//
//  WizardActivateViewController.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 10/01/2014.
//
//

#import "WizardActivateViewController.h"
#import "LinphoneManager.h"
#import "LinphoneHelper.h"

#import "SVProgressHUD.h"
#import "RestKit/RestKit.h"
#import "MappingProvider.h"
#import "Status.h"

@interface WizardActivateViewController ()

@end



@implementation WizardActivateViewController

@synthesize userEmailTextField;
@synthesize activationCodeTextField;
@synthesize activateButton;



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

- (void)viewWillAppear:(BOOL)animated {
    
    // Set observer - Registration update listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdate:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    // Remove observer - Registration update listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneRegistrationUpdate
                                                  object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Update Event Functions

- (void)registrationUpdate:(NSNotification*)notif {
    int state = [[notif.userInfo objectForKey: @"state"] intValue];
    
    switch (state) {
        case LinphoneRegistrationOk: {
            
            // Registration done. Go back to root view and start the app
            [self dismissLoader];
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
        }
        case LinphoneRegistrationFailed: {
            
            UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR",nil)
                                                                message:NSLocalizedString(@"INTERNAL_REGISTRATION_ERROR", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"CONTINUE",nil)
                                                      otherButtonTitles:nil,nil];
            [self dismissLoader];
            [errorView show];
            
            break;
        }
            
        case LinphoneRegistrationNone:
        case LinphoneRegistrationCleared:
        case LinphoneRegistrationProgress:
            break;
        default:
            break;
    }
}



#pragma mark - User Event Functions

// Hide keyboard when clicked anywhere out of the textbox
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([activationCodeTextField isFirstResponder] && [touch view] != activationCodeTextField) {
        [activationCodeTextField resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

// Hide keyboard when clicked on the return button
-(IBAction)textFieldReturn:(id)sender
{
    [sender resignFirstResponder];
}

- (IBAction)activateButtonTapped:(UIButton *)sender {
    NSMutableString *errors = [NSMutableString string];
    
    if([activationCodeTextField.text length] == 0) {
        [errors appendString:NSLocalizedString(@"ENTER_THE_ACTIVATION_CODE", nil)];
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
        [self activateEmail:userEmailTextField.text activationCode:activationCodeTextField.text];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    // Restart wizard
    if (buttonIndex == 0) {
        userEmailTextField.text = nil;
        activationCodeTextField.text = nil;
            
        [[self navigationController] popToRootViewControllerAnimated:NO];
    }
    
    // Enter activation code again
    if (buttonIndex == 1) {
        activationCodeTextField.text = nil;
    }
}




#pragma mark - UI Functions

- (void)showLoader
{
    activationCodeTextField.enabled = NO;
    activateButton.enabled = NO;
    
    [SVProgressHUD show];
}

- (void)dismissLoader
{
    activationCodeTextField.enabled = YES;
    activateButton.enabled = YES;
    
    [SVProgressHUD dismiss];
}



#pragma mark - API Webservice Client Functions

- (void)activateEmail:(NSString*)email activationCode:(NSString*)activationCodeText {

    // Set request and parameters
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   email, @"email",
                                   activationCodeText, @"activationCode",
                                   nil];
    
    // Send Register email request
    [[RKObjectManager sharedManager] putObject:nil
                                           path:[NSString stringWithFormat:@"/v2/user/%@", email]
                                     parameters:params
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        // Get results: query results and user
        Status *status = [mappingResult.dictionary objectForKey:@""];
       
        // Check response
        if (status) {

            // Registration success. Go to the main screen
            // Skip user already message. In this case we still need to go to the main screen
            if (status.success || [status.status isEqualToString:@"USER_ALREADY_ACTIVATED"]) {
                [LinphoneHelper registerSip:email withPassword:activationCodeText];
            }
            
            // The activation code is not correct
            else if ([status.status isEqualToString:@"INVALID_ACTIVATION_CODE"]) {
                
                // Popup confirmation for validation code email
                UIAlertView* invalidActivationCodeView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"INVALID_ACTIVATION_CODE", nil)
                                                                                    message:NSLocalizedString(@"DO_YOU_WANT_TO_TRY_AGAIN", nil)
                                                                                   delegate:self
                                                                          cancelButtonTitle:@"NO"
                                                                          otherButtonTitles:@"YES", nil];
                [self dismissLoader];
                [invalidActivationCodeView show];
            }
            
            // Any other non-success message
            else {
                UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR",nil)
                                                                    message:NSLocalizedString(status.status, nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"CONTINUE",nil)
                                                          otherButtonTitles:nil,nil];
                [self dismissLoader];
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
            [self dismissLoader];
            [errorView show];
        }
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
        // Hide the loader animation
        [self dismissLoader];
        
        // Set default error message
        NSString *errorMessage = @"UNKOWN_ERROR_OCCURED";
        
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
