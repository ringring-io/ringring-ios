//
//  ChatViewController.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 05/02/2014.
//
//

#import "ChatViewController.h"
#import "CallerViewController.h"

#import "Settings.h"
#import "LinphoneManager.h"
#import "LinphoneHelper.h"
#import "Message.h"



#define kAckMessageTimeout 15
#define kPerformedSegueIdentiferAtIncall @"StartSecureCallSegue"

@interface ChatViewController ()
{
    NSMutableArray *messages;
    LinphoneCall *call;
    NSTimer *messageRefreshTimer;
}
@end



@implementation ChatViewController

@synthesize contact;
@synthesize navigationItem;
@synthesize backButtonItem;
@synthesize trashButtonItem;



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
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];
    
    messages = nil;
    messages = [[NSMutableArray alloc] init];
    
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
    
    if ([contact.fullName length] != 0) {
        self.navigationItem.prompt = contact.email;
        self.navigationItem.title = contact.fullName;
    }
    else {
        self.navigationItem.prompt = nil;
        self.navigationItem.title = contact.email;
    }
    
    self.messageInputView.textView.placeHolder = NSLocalizedString(@"New Message", nil);
    
    [self setBackgroundColor:[UIColor whiteColor]];    
}

- (void)viewWillAppear:(BOOL)animated {
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
    
    // Reload messages list
    [self reloadMessages];
    
    // Init Message Refresh Timer
    [self initMessageRefreshTimer];
    
    // Mark all message as read
    contact.hasUnreadMessages = NO;
    [Message markAllAsRead:contact.email];
}

- (void)viewWillDisappear:(BOOL)animated {
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
    
    // Stop Message Refresh Timer
    [self stopMessageRefreshTimer];
}




#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [messages count];
}

#pragma mark - Messages view delegate: REQUIRED

- (void)didSendText:(NSString *)text
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
                                         withExpiryTime:[NSNumber numberWithDouble:[Settings clearIntervalToTimeInterval:[Settings autoClearChatHistory]]]
                                               withText:text];

    message.messageState = MessageStateInProgress;
    [message save];
    
    // Send message
    LinphoneChatMessage *msg = linphone_chat_room_create_message(chatRoom, [[message sipMessage] UTF8String]);
    linphone_chat_message_set_user_data(msg, (__bridge void *)(message));
    linphone_chat_room_send_message2(chatRoom, msg, message_status, (__bridge void *)(self));
    
    // Add new to the tableview
    [messages addObject:message];
    [JSMessageSoundEffect playMessageSentSound];

    [self finishSend];
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

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.row];
    JSBubbleMessageType bubbleMessageType;
    
    switch ((MessageDirection)message.messageDirection) {
        case NoMessage:
            // Normally this case never active
            bubbleMessageType = JSBubbleMessageTypeIncoming;
            break;
        case IncomingMessage:
            bubbleMessageType = JSBubbleMessageTypeIncoming;
            break;
        case OutgoingMessage:
            bubbleMessageType = JSBubbleMessageTypeOutgoing;
            break;
    }
    
    return bubbleMessageType;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.row];
    UIImageView *imageView;

    switch ((MessageDirection)message.messageDirection) {
        case NoMessage:
            imageView = nil;
            break;
        case IncomingMessage:
            imageView = [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                                   color:[UIColor js_bubbleLightGrayColor]];
            break;
        case OutgoingMessage:
            imageView = [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                                   color:[UIColor js_bubbleBlueColor]];
            break;
    }

    return imageView;
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    return JSMessagesViewTimestampPolicyEveryThree;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    return JSMessagesViewAvatarPolicyIncomingOnly;
}

- (JSMessagesViewSubtitlePolicy)subtitlePolicy
{
    return JSMessagesViewSubtitlePolicyAll;
}

- (JSMessageInputViewStyle)inputViewStyle
{
    return JSMessageInputViewStyleFlat;
}

#pragma mark - Messages view delegate: OPTIONAL

//
//  *** Implement to customize cell further
//
- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if([cell messageType] == JSBubbleMessageTypeOutgoing) {
        cell.bubbleView.textView.textColor = [UIColor whiteColor];
        
        if([cell.bubbleView.textView respondsToSelector:@selector(linkTextAttributes)]) {
            NSMutableDictionary *attrs = [cell.bubbleView.textView.linkTextAttributes mutableCopy];
            [attrs setValue:[UIColor blueColor] forKey:UITextAttributeTextColor];
            
            cell.bubbleView.textView.linkTextAttributes = attrs;
        }
    }
    
    if(cell.timestampLabel) {
        cell.timestampLabel.textColor = [UIColor lightGrayColor];
        cell.timestampLabel.shadowOffset = CGSizeZero;
    }
    
    // Set subtitle color based on the message status
    if(cell.subtitleLabel) {
        if ([cell.subtitleLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateIdle], nil)].location!=NSNotFound) {
            cell.subtitleLabel.textColor = [UIColor orangeColor];
        }
        else if ([cell.subtitleLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateInProgress], nil)].location!=NSNotFound) {
            cell.subtitleLabel.textColor = [UIColor greenColor];
        }
        else if ([cell.subtitleLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateNotDelivered], nil)].location!=NSNotFound) {
            cell.subtitleLabel.textColor = [UIColor redColor];
        }
        else if ([cell.subtitleLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateDelivered], nil)].location!=NSNotFound) {
            cell.subtitleLabel.textColor = [UIColor yellowColor];
        }
        else if ([cell.subtitleLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateNotReceived], nil)].location!=NSNotFound) {
            cell.subtitleLabel.textColor = [UIColor redColor];
        }
        else if ([cell.subtitleLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateReceived], nil)].location!=NSNotFound) {
            cell.subtitleLabel.textColor = [UIColor lightGrayColor];
        }
        else if ([cell.subtitleLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateOpened], nil)].location!=NSNotFound) {
            cell.subtitleLabel.textColor = [UIColor lightGrayColor];
        }
        else if ([cell.subtitleLabel.text rangeOfString:NSLocalizedString([Message messageStateToString:MessageStateExpired], nil)].location!=NSNotFound) {
            cell.subtitleLabel.textColor = [UIColor redColor];
        }
    }
}

//  *** Required if using `JSMessagesViewTimestampPolicyCustom`
//
//  - (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
//

//  *** Implement to use a custom send button
//
//  The button's frame is set automatically for you
//
//  - (UIButton *)sendButtonForInputView
//

//  *** Implement to prevent auto-scrolling when message is added
//
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling
{
    return YES;
}

#pragma mark - Messages view data source: REQUIRED

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.row];
    message.indexPath = indexPath;
    return [message text];
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.row];
    return [message receivedDate];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [messages objectAtIndex:indexPath.row];
    UIImage *avatarImage = [JSAvatarImageFactory avatarImage:[message image]
                                             croppedToCircle:YES];
    return [[UIImageView alloc] initWithImage:avatarImage];
}

- (NSString *)subtitleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *subtitle;
    Message *message = [messages objectAtIndex:indexPath.row];

    // Generate timeToExpiry String
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval expiryDate = [message.openedDate timeIntervalSince1970] + [message.expiryTime intValue];
    NSString *timeToExpiry = [NSString stringWithFormat:@"%@ (%d secs to expiry)", NSLocalizedString([Message messageStateToString:message.messageState], nil), (int)(expiryDate - now)];

    // Set subtitle for Outgoing messages
    if (message.messageDirection == OutgoingMessage) {
        
        // Set status label
        if (message.messageState != MessageStateOpened) {
            subtitle = NSLocalizedString([Message messageStateToString:message.messageState], nil);
        }
        
        // Countdown expiry time if the message is opened on the other side
        else {
            subtitle = timeToExpiry;
        }
    }
    
    // Set subtitle for Incoming message
    else if(message.messageDirection == IncomingMessage) {
        if (message.messageState != MessageStateExpired) {
            subtitle = timeToExpiry;
        }
        else {
            subtitle = NSLocalizedString([Message messageStateToString:message.messageState], nil);
        }
    }
    
    return subtitle;
}

- (IBAction)backButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)trashButtonTapped:(id)sender {
    
    // Delete expired messages
    [Message deleteMessagesWithContactEmail:contact.email];
    
    // Reload messages
    [self reloadMessages];
    [self refreshMessages:nil];
    
    // Clear chat window
    [self.tableView reloadData];
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
    
    [self updateApplicationBadgeNumber];
}

- (void)updateApplicationBadgeNumber {
    int count = 0;
    count += linphone_core_get_missed_calls_count([LinphoneManager getLc]);
    
    //count += [ChatModel unreadMessages];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
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
                [JSMessageSoundEffect playMessageReceivedSound];
                
                [self finishSend];
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
                        [self refreshMessageRow:curMessage.indexPath];

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



#pragma mark - Segue Functions

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if (sender == self) {
        
        // Pass selectedContact to the secure call view
        if([segue.identifier isEqualToString:kPerformedSegueIdentiferAtIncall]){
            CallerViewController *callerViewController = (CallerViewController *)segue.destinationViewController;
            
            // This is an incoming call
            if (call && callerViewController.callType == kNone) {
                callerViewController.callType = kIncoming;
                callerViewController.incomingCall = call;
                callerViewController.contact = nil;
                
                // reset call pointer
                call = nil;
            }
        }
    }
}



#pragma mark -

- (void)reloadMessages
{
    // Remove old data
    [messages removeAllObjects];
    
    // Delete expired messages
    [Message deleteExpiredMessages];
    
    // Reload current chat room messages
    messages = [Message listMessages:contact.email];
}

- (void)refreshMessages:(NSTimer *) aTimer
{
    NSDate *now = [NSDate date];
    bool isReloadMessageNeeded = NO;
    
    // Find the referenced message on the screen
    for (Message *curMessage in messages) {
        NSTimeInterval messageAge = [now timeIntervalSinceDate:curMessage.receivedDate];
        NSTimeInterval expiryDate = [curMessage.openedDate timeIntervalSince1970] + [curMessage.expiryTime intValue];
        int timeToExpiry = (int)(expiryDate - [now timeIntervalSince1970]);
        
        // Ack timeout, update to message status as not received
        if (curMessage.messageState == MessageStateInProgress && messageAge > kAckMessageTimeout) {
            curMessage.messageState = MessageStateNotReceived;
        
            // Update in the database and refresh on screen
            [curMessage update];
            [self refreshMessageRow:curMessage.indexPath];
        }

        // Message is opened, refresh expiry time
        if (curMessage.messageState == MessageStateOpened) {
        
            // Message is expired
            if (timeToExpiry < 0) {
                curMessage.messageState = MessageStateExpired;
                [curMessage update];
            }
            
            [self refreshMessageRow:curMessage.indexPath];
            //isReloadMessageNeeded = YES;
        }
    }

    if (isReloadMessageNeeded) {
        [self reloadMessages];
    }
}

- (void)refreshMessageRow:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
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
