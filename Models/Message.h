//
//  Message.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 08/02/2014.
//
//

#import <Foundation/Foundation.h>
#import "Contact.h"

typedef enum MessageDirection : NSUInteger {
    NoMessage,
    IncomingMessage,
    OutgoingMessage
} MessageDirection;

typedef enum MessageType : NSUInteger {
    UnknownMessage,
    TextMessage,
    AckMessage,
    OpenedMessage
} MessageType;

typedef enum MessageState : NSUInteger {
    MessageStateIdle,
    MessageStateInProgress,
    MessageStateDelivered,
    MessageStateNotDelivered,
    MessageStateReceived,
    MessageStateNotReceived,
    MessageStateWaitingtoOpen,
    MessageStateOpened,
    MessageStateExpired
} MessageState;

@interface Message : Contact

@property (nonatomic, copy) NSNumber *chatId;
@property (nonatomic, copy) NSNumber *refChatId;
@property (readwrite) enum MessageDirection messageDirection;
@property (nonatomic) enum MessageType messageType;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *sipMessage;
@property (nonatomic, copy) NSDate *receivedDate;
@property (nonatomic, copy) NSDate *openedDate;
@property (nonatomic) enum MessageState messageState;
@property (nonatomic, copy) NSNumber *expiryTime;
@property (nonatomic, copy) NSIndexPath *indexPath;

- (id)initWithContact:(Contact *)aContact
 withMessageDirection:(MessageDirection)aMessageDirection
      withMessageType:(MessageType)aMessageType
           withChatID:(NSNumber *)aChatID
        withRefChatId:(NSNumber *)aRefChatId
       withExpiryTime:(NSNumber *)anExpiryTime
             withText:(NSString *)aText;

- (id)initWithEmail:(NSString *)anEmail
withMessageDirection:(MessageDirection)aMessageDirection
    withMessageType:(MessageType)aMessageType
         withChatId:(NSNumber *)aChatID
      withRefChatId:(NSNumber *)aRefChatId
     withExpiryTime:(NSNumber *)anExpiryTime
           withText:(NSString *)aText;

- (id)initWithContact:(Contact *)aContact
 withMessageDirection:(MessageDirection)aMessageDirection
       withSipMessage:(NSString *)aSipMessage;

- (id)initWithEmail:(NSString *)anEmail
withMessageDirection:(MessageDirection)aMessageDirection
     withSipMessage:(NSString *)aSipMessage;

- (void)save;
- (void)update;
- (void)delete;

+ (bool)isValidSipMessage:(NSString *)aSipMessage;

+ (NSMutableArray *)listMessageLog;
+ (NSMutableArray *)listMessages:(NSString *)email;
+ (Message *)getMessage:(NSNumber *)chatId;
+ (NSNumber *)getUnreadMessages;
+ (void)markAllAsRead:(NSString *)email;
+ (void)deleteMessagesBeforeDate:(NSDate *)date;
+ (void)deleteMessagesWithContactEmail:(NSString *)contactEmail;
+ (void)updateExpiredMessages;
+ (void)deleteExpiredMessages;

+ (NSString *)messageDirectionToString:(MessageDirection)messageDirection;
+ (NSString *)messageTypeToString:(MessageType)messageType;
+ (NSString *)messageStateToString:(MessageState)messageState;

- (NSString *)description;

@end
