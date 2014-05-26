//
//  CallerViewController.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 14/01/2014.
//
//

#import <UIKit/UIKit.h>

#import "UIViewControllerWithStatusBar.h"
#import "Contact.h"
#import "LinphoneManager.h"

typedef enum {
    kNone,
    kIncoming,
    kOutgoing
} CallType;

@class CallerViewController;

@protocol CallerViewControllerDelegate <NSObject>

- (void)callerViewDidAddContact:(CallerViewController *)callerViewController;

@end

@interface CallerViewController : UIViewControllerWithStatusBar

@property (weak, nonatomic) id<CallerViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *registrationStateImage;
@property (weak, nonatomic) IBOutlet UILabel *registrationStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *registeredUserLabel;

@property (nonatomic, assign) LinphoneCall* incomingCall;
@property (nonatomic) CallType callType;
@property (nonatomic) Contact *contact;
@property (nonatomic, assign) BOOL isContactInAddressBook;

@property (weak, nonatomic) IBOutlet UINavigationItem *contactEmail;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *zrtpHashLabel;
@property (weak, nonatomic) IBOutlet UIImageView *contactImageView;
@property (weak, nonatomic) IBOutlet UIImageView *securityImageView;
@property (weak, nonatomic) IBOutlet UILabel *callTimerLabel;

@property (weak, nonatomic) IBOutlet UIButton *declineButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *hangupButton;


- (IBAction)declineButtonTapped:(id)sender;
- (IBAction)acceptButtonTapped:(id)sender;
- (IBAction)hangupButtonTapped:(id)sender;

@end


