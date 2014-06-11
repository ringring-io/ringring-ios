//
//  ChatViewController.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 05/02/2014.
//
//

#import "ChatViewController.h"

#import "LinphoneManager.h"
#import "LinphoneHelper.h"
#import "Settings.h"
#import "Message.h"

#define kAckMessageTimeout 15
#define kPerformedSegueIdentiferAtIncall @"StartSecureCallSegue"

@interface ChatViewController ()
{
    LinphoneCall *call;
    NSTimer *messageRefreshTimer;
}
@end


@implementation ChatViewController

@synthesize contact;
@synthesize navigationItem;
@synthesize messages;



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set headers
    if ([contact.fullName length] != 0) {
        self.navigationItem.prompt = contact.email;
        self.navigationItem.title = contact.fullName;
    }
    else {
        self.navigationItem.prompt = nil;
        self.navigationItem.title = contact.email;
    }
    
    // Remove camera button since media messages are not yet implemented
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    // Do not show avatar for outgoing messages
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    
    // Resize incoming contact avatar
    CGFloat incomingDiameter = self.collectionView.collectionViewLayout.incomingAvatarViewSize.width;
    contact.image = [JSQMessagesAvatarFactory avatarWithImage:contact.image
                                                   diameter:incomingDiameter];
    
    // Create outgoing bubble image
    self.outgoingBubbleImageView = [JSQMessagesBubbleImageFactory
                                    outgoingMessageBubbleImageViewWithColor:[UIColor jsq_messageBubbleGreenColor]];
    
    // Create incoming bubble image
    self.incomingBubbleImageView = [JSQMessagesBubbleImageFactory
                                    incomingMessageBubbleImageViewWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reload messages list
    [self reloadMessages];
    
    // Reload messages on the UI
    [self.collectionView reloadData];
    
    [super viewWillAppear:animated];
    
    // Set observer - Registration update listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdate:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    // Set observer - Call update listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdate:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
    
    // Set observer - Chat received listener
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textReceivedEvent:)
                                                 name:kLinphoneTextReceived
                                               object:nil];
    
    // Set observer - Wake up from background
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wakeUpFromBackground:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    // Init Message Refresh Timer
    [self initMessageRefreshTimer];
    
    // Mark all message as read
    contact.hasUnreadMessages = NO;
    [Message markAllAsRead:contact.email];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Enable/disable springy bubbles, default is YES.
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Remove observer - Registration update listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneRegistrationUpdate
                                                  object:nil];

    // Remove observer - Call update listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneCallUpdate
                                                  object:nil];

    // Remove observer - Chat received listener
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneTextReceived
                                                  object:nil];

    // Remove observer - Wake up from background
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];

    // Update application badge number
    [LinphoneHelper updateApplicationBadgeNumber];
    
    // Stop Message Refresh Timer
    [self stopMessageRefreshTimer];
}



#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                    sender:(NSString *)sender
                      date:(NSDate *)date
{
    if(![LinphoneManager isLcReady]) {
        [LinphoneHelper logc:LinphoneLoggerWarning format:"Cannot send message: Linphone core not ready"];
        return;
    }
    
    // Create chat room if not yet created
    if(chatRoom == NULL) {
		chatRoom = linphone_core_create_chat_room([LinphoneManager getLc], [[LinphoneHelper emailToSipUser:contact.email] UTF8String]);
    }
    
    // Save message in database
    Message *message = [[Message alloc] initWithContact:contact
                                   withMessageDirection:OutgoingMessage
                                        withMessageType:TextMessage
                                             withChatID:nil
                                          withRefChatId:nil
                                         withExpiryTime:[Settings isAutoClearChatHistoryEnabled]?[NSNumber numberWithDouble:[Settings clearIntervalToTimeInterval:[Settings autoClearChatHistory]]]:[NSNumber numberWithInt:0]
                                               withText:text];
    
    message.messageState = MessageStateInProgress;
    [message save];
    
    // Send message
    LinphoneChatMessage *msg = linphone_chat_room_create_message(chatRoom, [[message sipMessage] UTF8String]);
    linphone_chat_message_set_user_data(msg, (__bridge void *)(message));
    linphone_chat_room_send_message2(chatRoom, msg, message_status, (__bridge void *)(self));
    
    // Add new to the tableview
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    // Add message to the list
    [messages addObject:message];
    
    // JSQMessage send event
    [self finishSendingMessage];
    
    // Scroll to the bottom
    [self scrollToBottomAnimated:YES];
}

static void message_status(LinphoneChatMessage* msg,LinphoneChatMessageState state,void* ud) {
	Message *message = (__bridge Message *)linphone_chat_message_get_user_data(msg);
    
	[LinphoneHelper log:LinphoneLoggerLog
				 format:@"Delivery status for [%@] is [%s]",(message.text?message.text:@""),linphone_chat_message_state_to_string(state)];
	//[message setMessageState:[NSNumber numberWithInt:state]];
	//[message update];
    
	linphone_chat_message_set_user_data(msg, NULL);
}



#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.item];
    message.indexPath = indexPath;
    
    if(message.messageDirection == OutgoingMessage) {
        return [[JSQMessage alloc] initWithText:message.text sender:self.sender date:[NSDate date]];
    }
    else {
        return [[JSQMessage alloc] initWithText:message.text sender:message.email date:message.receivedDate];
    }
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView bubbleImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.item];
    
    // Reuse created bubble images, but create new imageView to add to each cell
    if (message.messageDirection == OutgoingMessage) {
        return [[UIImageView alloc] initWithImage:self.outgoingBubbleImageView.image
                                 highlightedImage:self.outgoingBubbleImageView.highlightedImage];
    }
    
    return [[UIImageView alloc] initWithImage:self.incomingBubbleImageView.image
                             highlightedImage:self.incomingBubbleImageView.highlightedImage];
    
     return nil;
}

- (UIImageView *)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageViewForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.item];
    
    // Do not show avatar for outgoing messages
    if (message.messageDirection == OutgoingMessage) {
        return nil;
    }

    return [[UIImageView alloc] initWithImage:contact.image];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // Show timestamp for every 3rd message
    // The other label text delegate methods should follow a similar pattern.
    Message *message = [messages objectAtIndex:indexPath.item];
    
    if (indexPath.item % 3 == 0) {
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.receivedDate];
    }

    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.item];

    // iOS7-style sender name labels
    if (!message.fullName) {
        return nil;
    }
    
    if (message.messageDirection == OutgoingMessage) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        Message *previousMessage = [messages objectAtIndex:indexPath.item - 1];
        if (previousMessage.messageDirection == OutgoingMessage) {
            return nil;
        }
    }
    
    return [[NSAttributedString alloc] initWithString:message.fullName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.row];
    NSString *subtitle = [[NSString alloc] init];

    // This is a self destructing message - Show expiry countdown
    if ([message.expiryTime intValue] != 0) {
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval expiryDate;
        
        // Calculate expiry date
        if (message.messageDirection == IncomingMessage) {
            expiryDate = [message.openedDate timeIntervalSince1970] + [message.expiryTime intValue];
        }
        else {
            expiryDate = [message.receivedDate timeIntervalSince1970] + [message.expiryTime intValue];
        }

        // Set subtitle to show expiry date count down
        subtitle = [NSString stringWithFormat:@"%d secs to expiry", (int)(expiryDate - now)];

        // Append status to outgoing messages only
        if (message.messageDirection == OutgoingMessage) {
            subtitle = [subtitle stringByAppendingFormat:@" (%@)", NSLocalizedString([Message messageStateToString:message.messageState],nil)];
        }
    }
    
    // This is a not a self destructing message - Do not show expiry countdown
    else {
        
        // Show status to outgoing messages only
        if (message.messageDirection == OutgoingMessage) {
            subtitle = NSLocalizedString([Message messageStateToString:message.messageState], nil);
        }
    }
    
    return [[NSAttributedString alloc] initWithString:subtitle];
}



#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.item];

    // Override point for customizing cells
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

    // Set text view colors
    if (message.messageDirection == OutgoingMessage) {
        cell.textView.textColor = [UIColor whiteColor];
    }
    else {
        cell.textView.textColor = [UIColor blackColor];
    }
    
    cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                          NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    
    // Set subtitle color based on the message status
    if(cell.cellBottomLabel) {
        if ([cell.cellBottomLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateIdle], nil)].location!=NSNotFound) {
            cell.cellBottomLabel.textColor = [UIColor orangeColor];
        }
        else if ([cell.cellBottomLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateInProgress], nil)].location!=NSNotFound) {
            cell.cellBottomLabel.textColor = [UIColor greenColor];
        }
        else if ([cell.cellBottomLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateNotDelivered], nil)].location!=NSNotFound) {
            cell.cellBottomLabel.textColor = [UIColor redColor];
        }
        else if ([cell.cellBottomLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateDelivered], nil)].location!=NSNotFound) {
            cell.cellBottomLabel.textColor = [UIColor yellowColor];
        }
        else if ([cell.cellBottomLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateNotReceived], nil)].location!=NSNotFound) {
            cell.cellBottomLabel.textColor = [UIColor redColor];
        }
        else if ([cell.cellBottomLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateReceived], nil)].location!=NSNotFound) {
            cell.cellBottomLabel.textColor = [UIColor lightGrayColor];
        }
        else if ([cell.cellBottomLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateOpened], nil)].location!=NSNotFound) {
            cell.cellBottomLabel.textColor = [UIColor lightGrayColor];
        }
        else if ([cell.cellBottomLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateExpired], nil)].location!=NSNotFound) {
            cell.cellBottomLabel.textColor = [UIColor redColor];
        }
    }
    
    return cell;
}



#pragma mark - JSQMessages collection view flow layout delegate

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    // Show timestamp for every 3rd message
    // The other label text delegate methods should follow a similar pattern.
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}



#pragma mark - Actions

- (IBAction)backButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)trashButtonTapped:(id)sender {
    
    // Delete every message from this contact
    [Message deleteMessagesWithContactEmail:contact.email];
    
    // Reload messages
    [self reloadMessages];
    
    // Clear chat window
    [self.collectionView reloadData];
}



#pragma mark - Update Event Functions

- (void)registrationUpdate: (NSNotification *) notif {
    
}

- (void)callUpdate: (NSNotification *) notif {
    LinphoneCall *aCall = [[notif.userInfo objectForKey: @"call"] pointerValue];
    LinphoneCallState callState = [[notif.userInfo objectForKey: @"state"] intValue];
    
	switch (callState) {
        case LinphoneCallIncomingReceived:      //  1: This is a new incoming call
        {
            // Switch to incoming call window
            if(kPerformedSegueIdentiferAtIncall != nil) {
                call = aCall;
                [self performSegueWithIdentifier:kPerformedSegueIdentiferAtIncall sender:self];
			}
            break;
        }
        default:
            break;
	}
    
    [LinphoneHelper updateApplicationBadgeNumber];
}

- (void)textReceivedEvent: (NSNotification *) notif {
    // Message is already saved in the database; just get the values from the notification event
    Message *message = [[notif.userInfo objectForKey:@"message"] pointerValue];
    
    // Add new message to the tableview if the message received from the current user
    if ([message.email isEqualToString:contact.email]) {
        
        switch ((MessageType)message.messageType) {
                
                // Show the new message on screen
            case TextMessage: {
                
                // Add message to the onscreen messages
                [messages addObject:message];
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                
                [self finishReceivingMessage];
                [self scrollToBottomAnimated:YES];
                
                // Send Opened Message to the other side
                [self sendOpenedMessage:message];
            }
                break;
                
                // Update message status on screen
            case AckMessage:
            case OpenedMessage: {
                
                Message *refMessage = [Message getMessage:message.refChatId];
                
                // Find the referenced message on the screen
                for (Message *curMessage in messages) {
                    if([curMessage.chatId intValue] == [refMessage.chatId intValue]) {
                        
                        // Sync message status on screen to received and refresh
                        curMessage.messageState = refMessage.messageState;
                        curMessage.openedDate = refMessage.openedDate;
                        
                        NSMutableArray *updatedIndexPaths = [[NSMutableArray alloc] initWithObjects: curMessage.indexPath, nil];
                        [self refreshMessageRows:updatedIndexPaths deleteIndexPaths:nil];
                        
                        break;
                    }
                }
            }
                break;
                
                // Do nothing on unknown incoming message
            case UnknownMessage:;
                break;
        }
    }
    
    // Show notification if the sender is not the current user on the screen
    else {
        self.navigationItem.prompt = [NSString stringWithFormat:NSLocalizedString(@"IM_MSG", nil), [LinphoneHelper sipUserToEmail:message.email]];
        self.navigationItem.title = contact.fullName;
    }
}

- (void)wakeUpFromBackground: (NSNotification *) notif {
    
    // Reload messages list
    //[self reloadMessages];
}

#pragma mark -

- (void)reloadMessages
{
    // Remove old data
    [messages removeAllObjects];
    
    // Re-calculate expiry times
    [Message updateExpiredMessages];
    
    // Delete expired messages
    [Message deleteExpiredMessages];
    
    // Reload current chat room messages
    messages = [Message listMessages:contact.email];

    // Mark all message to read from this user
    [Message markAllAsRead:contact.email];
}

- (void)refreshMessages:(NSTimer *) aTimer
{
    NSDate *now = [NSDate date];
    NSMutableArray *updateIndexPaths = [[NSMutableArray alloc] init];
    NSMutableArray *deleteIndexPaths = [[NSMutableArray alloc] init];
    
    // Find the referenced message on the screen
    for (Message *curMessage in messages) {
        NSTimeInterval messageAge = [now timeIntervalSinceDate:curMessage.openedDate];
        NSTimeInterval expiryDate;
        
        // Calculate expiry date
        if (curMessage.messageDirection == IncomingMessage) {
            expiryDate = [curMessage.openedDate timeIntervalSince1970] + [curMessage.expiryTime intValue];
        }
        else {
            expiryDate = [curMessage.receivedDate timeIntervalSince1970] + [curMessage.expiryTime intValue];
        }
        
        int timeToExpiry = (int)(expiryDate - [now timeIntervalSince1970]);

        // Ack timeout, update to message status as not received
        if (curMessage.messageState == MessageStateInProgress && messageAge > kAckMessageTimeout) {
            curMessage.messageState = MessageStateNotReceived;
            
            // Update in the database and refresh on screen
            [curMessage update];
            [updateIndexPaths addObject:curMessage.indexPath];
        }
        else if([curMessage.expiryTime intValue] != 0) {
        
            // Message is expired
            if (timeToExpiry <= 0) {
                curMessage.messageState = MessageStateExpired;
                [curMessage delete];

                [deleteIndexPaths addObject:curMessage.indexPath];
            }
            else {
                [updateIndexPaths addObject:curMessage.indexPath];
            }
        }
    }

    [self refreshMessageRows:updateIndexPaths deleteIndexPaths:deleteIndexPaths];
}

- (void)refreshMessageRows:(NSMutableArray *)updateIndexPaths deleteIndexPaths:(NSMutableArray *)deleteIndexPaths
{
    // Update required
    if(updateIndexPaths && [updateIndexPaths count] > 0) {

        // Update messages on the UI
        [self.collectionView reloadItemsAtIndexPaths:updateIndexPaths];
    }
    
    // Delete required
    if(deleteIndexPaths && [deleteIndexPaths count] > 0) {
            
        // Delete messages from message array
        NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
        for (NSIndexPath *indexPath in deleteIndexPaths)
            [indexes addIndex:indexPath.item];
        
        if ([indexes count] > 0)
            [messages removeObjectsAtIndexes:indexes];
             
        // Delete message on the UI
        [self.collectionView deleteItemsAtIndexPaths:deleteIndexPaths];
    }
}

- (void)sendOpenedMessage:(Message *)message
{
    // Prepare OPN message with MD5 checksum of the incoming message
    Message *opnMessage = [[Message alloc] initWithEmail:message.email
                                    withMessageDirection:OutgoingMessage
                                         withMessageType:OpenedMessage
                                              withChatId:message.chatId
                                           withRefChatId:message.refChatId
                                          withExpiryTime:message.expiryTime
                                                withText:[LinphoneHelper MD5String:message.text]];
    
    // Save onscreen message status to Opened
    message.messageState = MessageStateOpened;
    message.openedDate = [NSDate date];
    [message update];
    
    // Create chat room if not yet created
    if(chatRoom == NULL) {
        chatRoom = linphone_core_create_chat_room([LinphoneManager getLc], [[LinphoneHelper emailToSipUser:contact.email] UTF8String]);
    }
    
    // Send OPN message
    LinphoneChatMessage *opnMsg = linphone_chat_room_create_message(chatRoom, [opnMessage.sipMessage UTF8String]);
    linphone_chat_room_send_message2(chatRoom, opnMsg, nil, (__bridge void *)(self));
}


#pragma mark - Message Refresh Timer Functions

- (void)initMessageRefreshTimer {
    messageRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                           target:self
                                                         selector:@selector(refreshMessages:)
                                                         userInfo:nil
                                                          repeats:TRUE];
}

- (void)stopMessageRefreshTimer {
    
    if (messageRefreshTimer) {
        [messageRefreshTimer invalidate];
        messageRefreshTimer = nil;
    }
}

@end
