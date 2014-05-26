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


@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashButtonItem;

- (IBAction)backButtonTapped:(id)sender;
- (IBAction)trashButtonTapped:(id)sender;

@end
