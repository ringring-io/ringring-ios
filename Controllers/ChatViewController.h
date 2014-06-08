//
//  ChatViewController.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 05/02/2014.
//
//

#import "Contact.h"
#import "JSQMessages.h"

#import "linphonecore.h"

@class ChatViewController;


@protocol ChatViewControllerDelegate <NSObject>

- (void)didDismissChatViewController:(ChatViewController *)vc;

@end




@interface ChatViewController : JSQMessagesViewController {
    LinphoneChatRoom *chatRoom;
}

@property (weak, nonatomic) id<ChatViewControllerDelegate> delegateModal;

@property(nonatomic, weak) Contact *contact;

@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic) UIImageView *outgoingBubbleImageView;
@property (strong, nonatomic) UIImageView *incomingBubbleImageView;

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

- (IBAction)backButtonTapped:(id)sender;
- (IBAction)trashButtonTapped:(id)sender;

@end
