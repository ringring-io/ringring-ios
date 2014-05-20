//
//  ChatViewController.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 05/02/2014.
//
//

#import "JSMessagesViewController.h"
#import "Contact.h"

#include "linphonecore.h"

@interface ChatViewController : JSMessagesViewController <JSMessagesViewDataSource, JSMessagesViewDelegate> {
    LinphoneChatRoom *chatRoom;
}

@property(nonatomic, weak) Contact *contact;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

- (IBAction)backButtonTapped:(id)sender;

@end
