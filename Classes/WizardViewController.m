/* WizardViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU Library General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */ 

#import "WizardViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

#import "RestKit/RestKit.h"

typedef enum _ViewElement {
    ViewElement_Email = 100,
    ViewElement_ActivationCode = 101
} ViewElement;

typedef enum _AlertView {
    AlertView_EmailAlreadyRegistered = 100,
    AlertView_InvalidActivationCode = 102
} AlertView;

@implementation WizardViewController

@synthesize contentView;

@synthesize registerEmailView;
@synthesize activateEmailView;

@synthesize waitView;

@synthesize backButton;

@synthesize viewTapGestureRecognizer;

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"WizardViewController" bundle:[NSBundle mainBundle]];
    if (self != nil) {
        [[NSBundle mainBundle] loadNibNamed:@"WizardViews"
                                      owner:self
                                    options:nil];
        self->historyViews = [[NSMutableArray alloc] init];
        self->currentView = nil;
        self->viewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewTap:)];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [contentView release];
    
    [registerEmailView release];
    [activateEmailView release];
    
    [waitView release];
    
    [backButton release];
    
    [historyViews release];
    
    [viewTapGestureRecognizer release];
    
    [super dealloc];
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Wizard" 
                                                                content:@"WizardViewController" 
                                                               stateBar:nil 
                                                        stateBarEnabled:false 
                                                                 tabBar:nil 
                                                          tabBarEnabled:false 
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
    }
    return compositeDescription;
}


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdateEvent:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [viewTapGestureRecognizer setCancelsTouchesInView:FALSE];
    [viewTapGestureRecognizer setDelegate:self];
    [contentView addGestureRecognizer:viewTapGestureRecognizer];
    
    if([LinphoneManager runningOnIpad]) {
        [LinphoneUtils adjustFontSize:registerEmailView mult:2.22f];
        [LinphoneUtils adjustFontSize:activateEmailView mult:2.22f];
    }
}


#pragma mark -

+ (void)cleanTextField:(UIView*)view {
    if([view isKindOfClass:[UITextField class]]) {
        [(UITextField*)view setText:@""];
    } else {
        for(UIView *subview in view.subviews) {
            [WizardViewController cleanTextField:subview];
        }
    }
}

- (void)reset {
    [self clearProxyConfig];
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"pushnotification_preference"];
    
    LinphoneCore *lc = [LinphoneManager getLc];
    LCSipTransports transportValue={0};
    transportValue.udp_port=0;
    transportValue.tls_port=0;
    transportValue.tcp_port=5060;
    
    if (linphone_core_set_sip_transports(lc, &transportValue)) {
        [LinphoneLogger logc:LinphoneLoggerError format:"cannot set transport"];
    }
    
    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"sharing_server_preference"];
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"ice_preference"];
    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"stun_preference"];
    linphone_core_set_stun_server(lc, NULL);
    linphone_core_set_firewall_policy(lc, LinphonePolicyNoFirewall);
    [WizardViewController cleanTextField:registerEmailView];
    [WizardViewController cleanTextField:activateEmailView];
    [self changeView:registerEmailView back:FALSE animation:FALSE];
    [waitView setHidden:TRUE];
}

+ (UIView*)findView:(ViewElement)tag view:(UIView*)view {
    for(UIView *child in [view subviews]) {
        if([child tag] == tag){
            return (UITextField*)child;
        } else {
            UIView *o = [WizardViewController findView:tag view:child];
            if(o)
                return o;
        }
    }
    return nil;
}

+ (UITextField*)findTextField:(ViewElement)tag view:(UIView*)view {
    UIView *aview = [WizardViewController findView:tag view:view];
    if([aview isKindOfClass:[UITextField class]])
        return (UITextField*)aview;
    return nil;
}

+ (UILabel*)findLabel:(ViewElement)tag view:(UIView*)view {
    UIView *aview = [WizardViewController findView:tag view:view];
    if([aview isKindOfClass:[UILabel class]])
        return (UILabel*)aview;
    return nil;
}

- (void)clearHistory {
    [historyViews removeAllObjects];
}

- (void)changeView:(UIView *)view back:(BOOL)back animation:(BOOL)animation {
    // Change toolbar buttons following view
    //if (view == welcomeView) {
        [backButton setHidden:true];
    //}
    
    if (view == activateEmailView) {
        [backButton setEnabled:FALSE];
    } else {
        [backButton setEnabled:TRUE];
    }
    
    // Animation
    if(animation && [[LinphoneManager instance] lpConfigBoolForKey:@"animations_preference"] == true) {
      CATransition* trans = [CATransition animation];
      [trans setType:kCATransitionPush];
      [trans setDuration:0.35];
      [trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
      if(back) {
          [trans setSubtype:kCATransitionFromLeft];
      }else {
          [trans setSubtype:kCATransitionFromRight];
      }
      [contentView.layer addAnimation:trans forKey:@"Transition"];
    }
    
    // Stack current view
    if(currentView != nil) {
        if(!back)
            [historyViews addObject:currentView];
        [currentView removeFromSuperview];
    }
    
    // Set current view
    currentView = view;
    [contentView insertSubview:view atIndex:0];
    [view setFrame:[contentView bounds]];
    [contentView setContentSize:[view bounds].size];
}

- (void)clearProxyConfig {
	linphone_core_clear_proxy_config([LinphoneManager getLc]);
	linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}

- (void)setDefaultSettings:(LinphoneProxyConfig*)proxyCfg {
    BOOL pushnotification = [[LinphoneManager instance] lpConfigBoolForKey:@"push_notification" forSection:@"wizard"];
    [[LinphoneManager instance] lpConfigSetBool:pushnotification forKey:@"pushnotification_preference"];
    if(pushnotification) {
        [[LinphoneManager instance] addPushTokenToProxyConfig:proxyCfg];
    }
    int expires = [[LinphoneManager instance] lpConfigIntForKey:@"expires" forSection:@"wizard"];
    linphone_proxy_config_expires(proxyCfg, expires);
    
    NSString* transport = [[LinphoneManager instance] lpConfigStringForKey:@"transport" forSection:@"wizard"];
    LinphoneCore *lc = [LinphoneManager getLc];
    LCSipTransports transportValue={0};
	if (transport!=nil) {
		if (linphone_core_get_sip_transports(lc, &transportValue)) {
			[LinphoneLogger logc:LinphoneLoggerError format:"cannot get current transport"];
		}
		// Only one port can be set at one time, the others's value is 0
		if ([transport isEqualToString:@"tcp"]) {
			transportValue.tcp_port=transportValue.tcp_port|transportValue.udp_port|transportValue.tls_port;
			transportValue.udp_port=0;
            transportValue.tls_port=0;
		} else if ([transport isEqualToString:@"udp"]){
			transportValue.udp_port=transportValue.tcp_port|transportValue.udp_port|transportValue.tls_port;
			transportValue.tcp_port=0;
            transportValue.tls_port=0;
		} else if ([transport isEqualToString:@"tls"]){
			transportValue.tls_port=transportValue.tcp_port|transportValue.udp_port|transportValue.tls_port;
			transportValue.tcp_port=0;
            transportValue.udp_port=0;
		} else {
			[LinphoneLogger logc:LinphoneLoggerError format:"unexpected transport [%s]",[transport cStringUsingEncoding:[NSString defaultCStringEncoding]]];
		}
		if (linphone_core_set_sip_transports(lc, &transportValue)) {
			[LinphoneLogger logc:LinphoneLoggerError format:"cannot set transport"];
		}
	}
    
    NSString* sharing_server = [[LinphoneManager instance] lpConfigStringForKey:@"sharing_server" forSection:@"wizard"];
    [[LinphoneManager instance] lpConfigSetString:sharing_server forKey:@"sharing_server_preference"];
    
    BOOL ice = [[LinphoneManager instance] lpConfigBoolForKey:@"ice" forSection:@"wizard"];
    [[LinphoneManager instance] lpConfigSetBool:ice forKey:@"ice_preference"];
    
    NSString* stun = [[LinphoneManager instance] lpConfigStringForKey:@"stun" forSection:@"wizard"];
    [[LinphoneManager instance] lpConfigSetString:stun forKey:@"stun_preference"];
    
    if ([stun length] > 0){
        linphone_core_set_stun_server(lc, [stun UTF8String]);
        if(ice) {
            linphone_core_set_firewall_policy(lc, LinphonePolicyUseIce);
        } else {
            linphone_core_set_firewall_policy(lc, LinphonePolicyUseStun);
        }
    } else {
        linphone_core_set_stun_server(lc, NULL);
        linphone_core_set_firewall_policy(lc, LinphonePolicyNoFirewall);
    }
}

- (void)addProxyConfig:(NSString*)username password:(NSString*)password domain:(NSString*)domain server:(NSString*)server {
    [self clearProxyConfig];
    if(server == nil) {
        server = domain;
    }
	const char* identity = [[NSString stringWithFormat:@"sip:%@@%@", username, domain] UTF8String];
	LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config([LinphoneManager getLc]);
	LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String], NULL, [password UTF8String], NULL, NULL);
	linphone_proxy_config_set_identity(proxyCfg, identity);
	linphone_proxy_config_set_server_addr(proxyCfg, [server UTF8String]);
    if([server compare:domain options:NSCaseInsensitiveSearch] != 0) {
        linphone_proxy_config_set_route(proxyCfg, [server UTF8String]);
    }
    int defaultExpire = [[LinphoneManager instance] lpConfigIntForKey:@"default_expires"];
    if (defaultExpire >= 0)
        linphone_proxy_config_expires(proxyCfg, defaultExpire);
    if([domain compare:[[LinphoneManager instance] lpConfigStringForKey:@"domain" forSection:@"wizard"] options:NSCaseInsensitiveSearch] == 0) {
        [self setDefaultSettings:proxyCfg];
    }
    linphone_proxy_config_enable_register(proxyCfg, true);
    linphone_core_add_proxy_config([LinphoneManager getLc], proxyCfg);
	linphone_core_set_default_proxy([LinphoneManager getLc], proxyCfg);
	linphone_core_add_auth_info([LinphoneManager getLc], info);
}

- (void)registerEmail:(NSString*)email {
    
    RKObjectManager* objectManager = [RKObjectManager sharedManager];
    NSDictionary* params = [[NSDictionary alloc] initWithObjectsAndKeys: email, @"email", nil];
    
    [[objectManager HTTPClient]setParameterEncoding:AFJSONParameterEncoding];
    [[objectManager HTTPClient]postPath:@"users" parameters:params
                                success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary *jsonErrorArray = [((NSDictionary *)responseObject) valueForKey: @"error"];
         
         if(jsonErrorArray != nil) {
             NSString *jsonErrorCode = [jsonErrorArray objectForKey: @"code"];
             NSString *jsonErrorMessage = [jsonErrorArray objectForKey: @"message"];
         
             // Catch email is already registered error
             if([jsonErrorCode isEqual: @"101"]) {
                 // Popup confirmation for validation code email
                 alertViewId = AlertView_EmailAlreadyRegistered;
                 UIAlertView* userExistsView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email is already registered", nil)
                                                                          message:NSLocalizedString(@"Do you want to receive a new activation code?", nil)
                                                                         delegate:self
                                                                cancelButtonTitle:@"No"
                                                                otherButtonTitles:@"Yes", nil];
                 [waitView setHidden:true];
                 [userExistsView show];
                 [userExistsView release];
             }
             else {
                 UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                                     message:NSLocalizedString(jsonErrorMessage, nil)
                                                                    delegate:nil
                                                           cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                           otherButtonTitles:nil,nil];
                 [waitView setHidden:true];
                 [errorView show];
                 [errorView release];

             }
         } else {
             
             [waitView setHidden:true];
             [self changeView:activateEmailView back:FALSE animation:TRUE];
         }
     }
                                failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSString *errorMessage = @"";

         // Check internet connection error
         if([error code] == -1009) {
             errorMessage = [error localizedDescription];
         } else {
             errorMessage = [NSString stringWithFormat:@"Internal Zirgoo communication error. (Code: %d)", [error code]];
         }
         
         UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                             message:NSLocalizedString(errorMessage, nil)
                                                            delegate:nil
                                                   cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                   otherButtonTitles:nil,nil];
         [waitView setHidden:true];
         [errorView show];
         [errorView release];
     }];
}

- (void)renewActivationCode:(NSString*)email {
    
    RKObjectManager* objectManager = [RKObjectManager sharedManager];
    NSDictionary* params = [[NSDictionary alloc] initWithObjectsAndKeys: email, @"email", nil];
    
    [[objectManager HTTPClient]setParameterEncoding:AFJSONParameterEncoding];
    [[objectManager HTTPClient]postPath:@"users/renewactivationcode" parameters:params
                                success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary *jsonErrorArray = [((NSDictionary *)responseObject) valueForKey: @"error"];
         
         if(jsonErrorArray != nil) {
             NSString *jsonErrorMessage = [jsonErrorArray objectForKey: @"message"];
            
             UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                                 message:NSLocalizedString(jsonErrorMessage, nil)
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                       otherButtonTitles:nil,nil];
             [waitView setHidden:true];
             [errorView show];
             [errorView release];
         }
         else {
             
             [waitView setHidden:true];
             [self changeView:activateEmailView back:FALSE animation:TRUE];
         }
             
     }
                                failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSString *errorMessage = @"";
             
         // Check internet connection error
         if([error code] == -1009) {
             errorMessage = [error localizedDescription];
         } else {
             errorMessage = [NSString stringWithFormat:@"Internal Zirgoo communication error. (Code: %d)", [error code]];
         }
             
         UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                             message:NSLocalizedString(errorMessage, nil)
                                                            delegate:nil
                                                   cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                   otherButtonTitles:nil,nil];
         [waitView setHidden:true];
         [errorView show];
         [errorView release];
     }];
}

- (void)activateEmail:(NSString*)email activationCode:(NSString*)activationCode {
    
    RKObjectManager* objectManager = [RKObjectManager sharedManager];
    NSDictionary* params = [[NSDictionary alloc] initWithObjectsAndKeys: email, @"email", activationCode, @"activation_code", nil];
    
    [[objectManager HTTPClient]setParameterEncoding:AFJSONParameterEncoding];
    [[objectManager HTTPClient]postPath:@"users/activate" parameters:params
                                success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSDictionary *jsonErrorArray = [((NSDictionary *)responseObject) valueForKey: @"error"];
         
         if(jsonErrorArray != nil) {
             NSString *jsonErrorCode = [jsonErrorArray objectForKey: @"code"];
             NSString *jsonErrorMessage = [jsonErrorArray objectForKey: @"message"];
             
             // Catch invalid email or activation code error
             if([jsonErrorCode isEqual: @"104"]) {
                 // Popup confirmation for validation code email
                 alertViewId = AlertView_InvalidActivationCode;
                 UIAlertView* invalidActivationCodeView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid activation code", nil)
                                                                          message:NSLocalizedString(@"Do you want to try again?", nil)
                                                                         delegate:self
                                                                cancelButtonTitle:@"No"
                                                                otherButtonTitles:@"Yes", nil];
                 [waitView setHidden:true];
                 [invalidActivationCodeView show];
                 [invalidActivationCodeView release];
             }
             
             // Skip user is already activated error
             else if(![jsonErrorCode isEqual: @"103"]) {
                 UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                                     message:NSLocalizedString(jsonErrorMessage, nil)
                                                                    delegate:nil
                                                           cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                           otherButtonTitles:nil,nil];
                 [waitView setHidden:true];
                 [errorView show];
                 [errorView release];
             }
             else {
                 [self signIn:email password:activationCode];
             }
         }
         else {
             [self signIn:email password:activationCode];
         }
     }
                                failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSString *errorMessage = @"";
         
         // Check internet connection error
         if([error code] == -1009) {
             errorMessage = [error localizedDescription];
         } else {
             errorMessage = [NSString stringWithFormat:@"Internal Zirgoo communication error. (Code: %d)", [error code]];
         }
         
         UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                             message:NSLocalizedString(errorMessage, nil)
                                                            delegate:nil
                                                   cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                   otherButtonTitles:nil,nil];
         [waitView setHidden:true];
         [errorView show];
         [errorView release];
     }];
}

- (void)signIn:(NSString*)email password:(NSString*)password {
    
    // Convert email to sip friendly usernames
    NSString *userName = [email stringByReplacingOccurrencesOfString: @"@"
                                                withString: @"_AT_"];
    
    // Register to SIP server
    [self addProxyConfig:userName password:password
                  domain:[[LinphoneManager instance] lpConfigStringForKey:@"domain" forSection:@"wizard"]
                  server:[[LinphoneManager instance] lpConfigStringForKey:@"proxy" forSection:@"wizard"]];
}

- (void)registrationUpdate:(LinphoneRegistrationState)state {
    switch (state) {
        case LinphoneRegistrationOk: {
            [waitView setHidden:true];
            [[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
            break;
        }
        case LinphoneRegistrationFailed: {
            
            NSString *errorMessage = [NSString stringWithFormat:@"Internal Zirgoo registration error."];
            
            UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil)
                                                                message:NSLocalizedString(errorMessage, nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                      otherButtonTitles:nil,nil];
            [waitView setHidden:true];
            [errorView show];
            [errorView release];
            
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


#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeTextField = textField;
}


#pragma mark - Action Functions


- (IBAction)onBackClick:(id)sender {
    if ([historyViews count] > 0) {
        UIView * view = [historyViews lastObject];
        [historyViews removeLastObject];
        [self changeView:view back:TRUE animation:TRUE];
    }
}

- (IBAction)onRegisterEmailClick:(id)sender {
    NSString *email = [WizardViewController findTextField:ViewElement_Email view:contentView].text;
    NSMutableString *errors = [NSMutableString string];
    
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".+@.+\\.[A-Za-z]{2}[A-Za-z]*"];
    if(![emailTest evaluateWithObject:email]) {
        [errors appendString:NSLocalizedString(@"The email is invalid.\n", nil)];
    }
    
    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                        message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                              otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];
    } else {
        [waitView setHidden:false];
        userEmail = email;
        [self registerEmail:email];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertViewId == AlertView_EmailAlreadyRegistered) {
        // Request for new activation code
        if (buttonIndex == 1)
        {
            NSString *email = [WizardViewController findTextField:ViewElement_Email view:contentView].text;
            
            [waitView setHidden:false];
            [self renewActivationCode:email];
        }
        
    }
    else if(alertViewId == AlertView_InvalidActivationCode) {
        // Request for new activation code
        if (buttonIndex == 0)
        {
            
            [WizardViewController cleanTextField:registerEmailView];
            [WizardViewController cleanTextField:activateEmailView];
            
            [self changeView:registerEmailView back:FALSE animation:FALSE];
            [waitView setHidden:TRUE];
        }
    }
}


- (IBAction)onActivateEmailClick:(id)sender {
    NSString *activationCode = [WizardViewController findTextField:ViewElement_ActivationCode view:contentView].text;
    NSMutableString *errors = [NSMutableString string];
    
    if([activationCode length] == 0) {
        [errors appendString:NSLocalizedString(@"Enter the activation code.\n", nil)];
    }
    
    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];
    } else {
        [waitView setHidden:false];
        [self activateEmail:userEmail activationCode:activationCode];    }
}

- (IBAction)onViewTap:(id)sender {
    [LinphoneUtils findAndResignFirstResponder:currentView];
}


#pragma mark - Event Functions

- (void)registrationUpdateEvent:(NSNotification*)notif {
    [self registrationUpdate:[[notif.userInfo objectForKey: @"state"] intValue]];
}


#pragma mark - Keyboard Event Functions

- (void)keyboardWillHide:(NSNotification *)notif {
    //CGRect beginFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    //CGRect endFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[[notif userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval duration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:@"resize" context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    
    // Move view
    UIEdgeInsets inset = {0, 0, 0, 0};
    [contentView setContentInset:inset];
    [contentView setScrollIndicatorInsets:inset];
    [contentView setShowsVerticalScrollIndicator:FALSE];
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notif {
    //CGRect beginFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[[notif userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval duration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:@"resize" context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        int width = endFrame.size.height;
        endFrame.size.height = endFrame.size.width;
        endFrame.size.width = width;
    }
    
    // Change inset
    {
        UIEdgeInsets inset = {0,0,0,0};
        CGRect frame = [contentView frame];
        CGRect rect = [PhoneMainView instance].view.bounds;
        CGPoint pos = {frame.size.width, frame.size.height};
        CGPoint gPos = [contentView convertPoint:pos toView:[UIApplication sharedApplication].keyWindow.rootViewController.view]; // Bypass IOS bug on landscape mode
        inset.bottom = -(rect.size.height - gPos.y - endFrame.size.height);
        if(inset.bottom < 0) inset.bottom = 0;
        
        [contentView setContentInset:inset];
        [contentView setScrollIndicatorInsets:inset];
        CGRect fieldFrame = activeTextField.frame;
        fieldFrame.origin.y += fieldFrame.size.height;
        [contentView scrollRectToVisible:fieldFrame animated:TRUE];
        [contentView setShowsVerticalScrollIndicator:TRUE];
    }
    [UIView commitAnimations];
}


#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary*)attributesForView:(UIView*)view {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
    [attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
    if([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewAddAttributes:attributes button:button];
    }
    [attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];
    return attributes;
}

- (void)applyAttributes:(NSDictionary*)attributes toView:(UIView*)view {
    view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
    view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
    if([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewApplyAttributes:attributes button:button];
    }
    view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}


#pragma mark - UIGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIButton class]]) { //Avoid tap gesture on Button
        if([LinphoneUtils findAndResignFirstResponder:currentView]) {
            [(UIButton*)touch.view sendActionsForControlEvents:UIControlEventTouchUpInside];
            return NO;
        }
    }
    return YES;
}

@end
