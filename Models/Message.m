//
//  Message.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 08/02/2014.
//
//

#import "Message.h"
#import "Contact.h"
#import "AddressBookMap.h"
#import "LinphoneHelper.h"

@implementation Message

@synthesize chatId;
@synthesize refChatId;
@synthesize messageDirection;
@synthesize messageType;
@synthesize text;
@synthesize sipMessage;
@synthesize receivedDate;
@synthesize openedDate;
@synthesize messageState;
@synthesize expiryTime;
@synthesize indexPath;



// Generic workflow:
// -----------------
// 1) Alice sends a new message                           - "TYPE:TXT;CHAT_ID:123;EXPIRY:600;MESSAGE:Hello Bob"
// 2) Bob receives the message and saves it into his local
//    database
// 3) Bob sends an ack                                    - "TYPE:ACK;CHAT_ID:123;EXPIRY:0;MESSAGE:md5sum(Hello Bob)"
// 4) Alice receives the ack and updates her message status
//    to Received if the received MD5 sum is correct
// 5) Bob opens the message and sends a read confirmation - "TYPE:CON;CHAT_ID:123;EXPIRY:0;MESSAGE:md5sum(Hello Bon)"
// 6) Alice receives the conf and updates her message
//    status to Read if the received MD5 sum is correct

- (id)initWithContact:(Contact *)aContact
 withMessageDirection:(MessageDirection)aMessageDirection
      withMessageType:(MessageType)aMessageType
           withChatID:(NSNumber *)aChatID
        withRefChatId:(NSNumber *)aRefChatId
       withExpiryTime:(NSNumber *)anExpiryTime
             withText:(NSString *)aText
{
    self = [super initWithContact:aContact];
    
    if (self != nil) {
        self.messageDirection = aMessageDirection;
        self.messageType = aMessageType;
        self.chatId = aChatID;
        self.refChatId = aRefChatId;
        self.expiryTime = anExpiryTime;
        self.text = aText;
        self.receivedDate = [NSDate date];
        self.openedDate = nil;
        self.messageState = MessageStateIdle;
        
        [NSNumber numberWithInteger:0];
        
        [self refreshSipMessage];
    }
    
    return self;
}

- (id)initWithEmail:(NSString *)anEmail
withMessageDirection:(MessageDirection)aMessageDirection
    withMessageType:(MessageType)aMessageType
         withChatId:(NSNumber *)aChatID
      withRefChatId:(NSNumber *)aRefChatId
     withExpiryTime:(NSNumber *)anExpiryTime
           withText:(NSString *)aText
{
    Contact *contact = nil;
    
    // Try to get contact from the addressbook by email
    contact = [AddressBookMap getContactWithEmail:anEmail];
    
    // No contact found; create a default one
    if (contact == nil) {
        contact = [[Contact alloc] initWithDefault:anEmail];
    }
    
    self = [self initWithContact:contact
            withMessageDirection:aMessageDirection
                 withMessageType:aMessageType
                      withChatID:aChatID
                   withRefChatId:aRefChatId
                  withExpiryTime:anExpiryTime
                        withText:aText];
    
    return self;
}

- (id)initWithContact:(Contact *)aContact
 withMessageDirection:(MessageDirection)aMessageDirection
          withSipMessage:(NSString *)aSipMessage
{
    self = [self initWithContact:aContact
            withMessageDirection:aMessageDirection
                 withMessageType:UnknownMessage
                      withChatID:nil
                   withRefChatId:nil
                  withExpiryTime:nil
                        withText:nil];
    
    // Extract message properties from sipMessage
    if (self != nil && [Message isValidSipMessage:aSipMessage]) {

        // Sample sipMessage: "TYPE:TXT;CHAT_ID:11;REF_CHAT_ID:123;EXPIRY_TIME;MESSAGE:Hello Bob"
        NSArray *sipTextComponents = [aSipMessage componentsSeparatedByString:@";"];
        NSString *sipTextComponent;
        NSRange range;
        
        // Extract Message Type
        sipTextComponent = [sipTextComponents objectAtIndex:0];
        range = [sipTextComponent rangeOfString:@":"];
        NSString *sMessageType = [sipTextComponent substringFromIndex:range.location + 1];
        if ([sMessageType isEqualToString:@"TXT"]) {
            self.messageType = TextMessage;
        }
        else if([sMessageType isEqualToString:@"ACK"]) {
            self.messageType = AckMessage;
        }
        else if([sMessageType isEqualToString:@"OPN"]) {
            self.messageType = OpenedMessage;
        }
        else {
            self.messageType = UnknownMessage;
        }
        
        // Extract Chat Id
        sipTextComponent = [sipTextComponents objectAtIndex:1];
        range = [sipTextComponent rangeOfString:@":"];
        NSString *sChatId = [[sipTextComponents objectAtIndex:1] substringFromIndex:range.location + 1];
        NSScanner *scannerChatId = [NSScanner scannerWithString:sChatId];
        int dChatId;
        
        if ([scannerChatId scanInt:&dChatId] && scannerChatId.scanLocation == sChatId.length) {
            self.chatId = [NSNumber numberWithInt:dChatId];
        }
        
        // Extract Ref Chat Id
        sipTextComponent = [sipTextComponents objectAtIndex:2];
        range = [sipTextComponent rangeOfString:@":"];
        NSString *sRefChatId = [[sipTextComponents objectAtIndex:2] substringFromIndex:range.location + 1];
        NSScanner *scannerRefChatId = [NSScanner scannerWithString:sRefChatId];
        int dRefChatId;
        
        if ([scannerRefChatId scanInt:&dRefChatId] && scannerRefChatId.scanLocation == sRefChatId.length) {
            self.refChatId = [NSNumber numberWithInt:dRefChatId];
        }
        
        // Extract Expiry Time
        sipTextComponent = [sipTextComponents objectAtIndex:3];
        range = [sipTextComponent rangeOfString:@":"];
        NSString *sExpiryTime = [[sipTextComponents objectAtIndex:3] substringFromIndex:range.location + 1];
        NSScanner *scannerExpiryTime = [NSScanner scannerWithString:sExpiryTime];
        int dExpiryTime;
        
        if ([scannerExpiryTime scanInt:&dExpiryTime] && scannerExpiryTime.scanLocation == sExpiryTime.length) {
            self.expiryTime = [NSNumber numberWithInt:dExpiryTime];
        }
        
        // Extract Text
        sipTextComponent = [sipTextComponents objectAtIndex:4];
        range = [sipTextComponent rangeOfString:@":"];
        NSString *sText = [sipTextComponent substringFromIndex:range.location + 1];
        self.text = sText;
        
        [self refreshSipMessage];
    }
    
    return self;
}

- (id)initWithEmail:(NSString *)anEmail
withMessageDirection:(MessageDirection)aMessageDirection
     withSipMessage:(NSString *)aSipMessage
{
    Contact *contact = nil;
    
    // Try to get contact from the addressbook by email
    contact = [AddressBookMap getContactWithEmail:anEmail];
    
    // No contact found; create a default one
    if (contact == nil) {
        contact = [[Contact alloc] initWithDefault:anEmail];
    }
    
    self = [self initWithContact:contact
            withMessageDirection:aMessageDirection
               withSipMessage:aSipMessage];
    
    return self;
}

- (id)initWithSqlStatement:(sqlite3_stmt *)sqlStatement
{
    self = [self initWithEmail:[NSString stringWithUTF8String: (const char*) sqlite3_column_text(sqlStatement, 2)]
          withMessageDirection:[[NSNumber numberWithInt:sqlite3_column_int(sqlStatement, 3)] intValue]
               withMessageType:[[NSNumber numberWithInt:sqlite3_column_int(sqlStatement, 4)] intValue]
                    withChatId:[NSNumber numberWithInt:sqlite3_column_int(sqlStatement, 0)]
                 withRefChatId:[NSNumber numberWithInt:sqlite3_column_int(sqlStatement, 1)]
                withExpiryTime:[NSNumber numberWithInt:sqlite3_column_int(sqlStatement, 9)]
                      withText:[NSString stringWithUTF8String: (const char*) sqlite3_column_text(sqlStatement, 5)]];
    
    if (self != nil) {
        self.receivedDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(sqlStatement, 6)];
        self.openedDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_int(sqlStatement, 7)];
        self.messageState = [[NSNumber numberWithInt:sqlite3_column_int(sqlStatement, 8)] intValue];
        
        [self refreshSipMessage];
    }

    return self;
}

- (void)save
{
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return;
    }
    
    const char *sql = "INSERT INTO chat (ref_id, contact_email, direction, type, text, received_date, opened_date, state, expiry_time) VALUES (@REF_ID, @CONTACT_EMAIL, @DIRECTION, @TYPE, @TEXT, @RECEIVED_DATE, @OPENED_DATE, @STATE, @EXPIRY_TIME)";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't prepare the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return;
    }
    
    // Prepare statement
    sqlite3_bind_int(sqlStatement, 1, [self.refChatId intValue]);
    sqlite3_bind_text(sqlStatement, 2, [self.email UTF8String], -1, SQLITE_STATIC);
    sqlite3_bind_int(sqlStatement, 3, self.messageDirection);
    sqlite3_bind_int(sqlStatement, 4, self.messageType);
    sqlite3_bind_text(sqlStatement, 5, [self.text UTF8String], -1, SQLITE_STATIC);
    sqlite3_bind_double(sqlStatement, 6, [self.receivedDate timeIntervalSince1970]);
    sqlite3_bind_double(sqlStatement, 7, [self.openedDate timeIntervalSince1970]);
	sqlite3_bind_int(sqlStatement, 8, self.messageState);
    sqlite3_bind_int(sqlStatement, 9, [self.expiryTime intValue]);
    
    if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        sqlite3_finalize(sqlStatement);
    }
    
    self.chatId = [[NSNumber alloc] initWithLong:(long)sqlite3_last_insert_rowid(database)];
    sqlite3_finalize(sqlStatement);
    
    [self refreshSipMessage];
}

- (void)update
{
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return;
    }
    
    const char *sql = "UPDATE chat SET ref_id=@REF_ID, contact_email=@CONTACT_EMAIL, direction=@DIRECTION, type=@TYPE, text=@TEXT, received_date=@RECEIVED_DATE, opened_date=@OPENED_DATE, state=@STATE, expiry_time=@EXPIRY_TIME WHERE id=@ID";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't prepare the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return;
    }
    
    // Prepare statement
    sqlite3_bind_int(sqlStatement, 1, [self.refChatId intValue]);
    sqlite3_bind_text(sqlStatement, 2, [self.email UTF8String], -1, SQLITE_STATIC);
    sqlite3_bind_int(sqlStatement, 3, self.messageDirection);
    sqlite3_bind_int(sqlStatement, 4, self.messageType);
    sqlite3_bind_text(sqlStatement, 5, [self.text UTF8String], -1, SQLITE_STATIC);
    sqlite3_bind_double(sqlStatement, 6, [self.receivedDate timeIntervalSince1970]);
    sqlite3_bind_double(sqlStatement, 7, [self.openedDate timeIntervalSince1970]);
    sqlite3_bind_int(sqlStatement, 8, self.messageState);
    sqlite3_bind_int(sqlStatement, 9, [self.expiryTime intValue]);
	sqlite3_bind_int(sqlStatement, 10, [self.chatId intValue]);
    
    if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        sqlite3_finalize(sqlStatement);
        return;
    }
    
    sqlite3_finalize(sqlStatement);
}

- (void)delete
{
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return;
    }
    
    const char *sql = "DELETE FROM chat WHERE id=@ID";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't prepare the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return;
    }
    
    // Prepare statement
    sqlite3_bind_int(sqlStatement, 1, [chatId intValue]);
    
    if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        sqlite3_finalize(sqlStatement);
        return;
    }
    
    sqlite3_finalize(sqlStatement);
}


+ (bool)isValidSipMessage:(NSString *)aSipMessage
{
    NSString *pattern = @"TYPE:.+;CHAT_ID:.+;REF_CHAT_ID:.+;EXPIRY_TIME:[0-9]+;MESSAGE:.*";
    NSPredicate *myTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    
    return [myTest evaluateWithObject: aSipMessage];
}

+ (NSMutableArray *)listMessageLog
{
    NSMutableArray *messages = [NSMutableArray array];
    
    // Connect to database
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return messages;
    }
    
    // Select the latest message from every email address
    const char *sql = "SELECT id, ref_id, contact_email, direction, type, text, received_date, opened_date, state, expiry_time FROM chat WHERE id IN (SELECT MAX(id) FROM chat GROUP BY contact_email) ORDER BY received_date ASC";
    
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't execute the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return messages;
    }
    
    int err;
    while ((err = sqlite3_step(sqlStatement)) == SQLITE_ROW) {
        Message *message = [[Message alloc] initWithSqlStatement:sqlStatement];
        [messages addObject:message];
    }
    
    if (err != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        return messages;
    }
    
    sqlite3_finalize(sqlStatement);
    
    return messages;
}

+ (NSMutableArray *)listMessages:(NSString *)email
{
    NSMutableArray *messages = [NSMutableArray array];
    
    // Connect to database
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return messages;
    }
    
    // Select every message from the remote email address
    const char *sql = "SELECT id, ref_id, contact_email, direction, type, text, received_date, opened_date, state, expiry_time FROM chat WHERE contact_email=@EMAIL ORDER BY received_date ASC";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't execute the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return messages;
    }
    
    // Prepare statement
    sqlite3_bind_text(sqlStatement, 1, [email UTF8String], -1, SQLITE_STATIC);
    
    int err;
    while ((err = sqlite3_step(sqlStatement)) == SQLITE_ROW) {
        Message *message = [[Message alloc] initWithSqlStatement:sqlStatement];
        
        // Send opened message if not yet sent
        if (message.messageDirection == IncomingMessage && message.messageState == MessageStateIdle) {
            
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

            // Send OPN
            LinphoneChatRoom *chatRoom = linphone_core_create_chat_room([LinphoneManager getLc], [[LinphoneHelper emailToSipUser:email] UTF8String]);
            LinphoneChatMessage *conMsg = linphone_chat_room_create_message(chatRoom, [opnMessage.sipMessage UTF8String]);
            linphone_chat_room_send_message2(chatRoom, conMsg, nil, (__bridge void *)(self));
        }
        
        [messages addObject:message];
    }
    
    if (err != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        return messages;
    }
    
    sqlite3_finalize(sqlStatement);
    
    return messages;
}

+ (Message *)getMessage:(NSNumber *)chatId
{
    Message *message = nil;
    
    // Connect to database
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return message;
    }
    
    // Select every message from the remote email address
    const char *sql = "SELECT id, ref_id, contact_email, direction, type, text, received_date, opened_date, state, expiry_time FROM chat WHERE id = @CHAT_ID";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't execute the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return message;
    }
    
    // Prepare statement
    sqlite3_bind_int(sqlStatement, 1, [chatId intValue]);
    
    int err;
    while ((err = sqlite3_step(sqlStatement)) == SQLITE_ROW) {
        message = [[Message alloc] initWithSqlStatement:sqlStatement];
    }
    
    if (err != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        return message;
    }
    
    sqlite3_finalize(sqlStatement);
    
    return message;
}

+ (void)markAllAsRead:(NSString *)email
{
    /*
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return;
    }
    
    const char *sql = "UPDATE chat SET read = 1 WHERE contact_email=@EMAIL";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't prepare the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return;
    }
    
    // Prepare statement
    sqlite3_bind_text(sqlStatement, 1, [email UTF8String], -1, SQLITE_STATIC);
    
    if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        sqlite3_finalize(sqlStatement);
        return;
    }
    
    sqlite3_finalize(sqlStatement);
     */
}

+ (void)deleteMessagesBeforeDate:(NSDate *)date
{
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return;
    }
    
    const char *sql = "DELETE FROM chat WHERE received_date<=@DATE";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't prepare the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return;
    }
    
    // Prepare statement
    sqlite3_bind_double(sqlStatement, 1, [date timeIntervalSince1970]);
    
    if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        sqlite3_finalize(sqlStatement);
        return;
    }
    
    sqlite3_finalize(sqlStatement);
}

+ (void)deleteMessagesWithContactEmail:(NSString *)contactEmail
{
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return;
    }

    const char *sql = "DELETE FROM chat WHERE contact_email=@EMAIL";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't prepare the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return;
    }
    
    // Prepare statement
    sqlite3_bind_text(sqlStatement, 1, [contactEmail UTF8String], -1, SQLITE_STATIC);
                                          
    if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        sqlite3_finalize(sqlStatement);
        return;
    }
    
    sqlite3_finalize(sqlStatement);
}

+ (void)updateExpiredMessages
{
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return;
    }
    
    const char *sql = "UPDATE chat SET state = @STATE WHERE expiry_time != 0 AND received_date + expiry_time <= @NOW";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't prepare the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return;
    }
    
    // Prepare statement
    sqlite3_bind_int(sqlStatement, 1, (int)MessageStateExpired);
    sqlite3_bind_double(sqlStatement, 2, [[NSDate date] timeIntervalSince1970]);
    
    if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        sqlite3_finalize(sqlStatement);
        return;
    }
    
    sqlite3_finalize(sqlStatement);
}

+ (void)deleteExpiredMessages
{
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return;
    }
    
    const char *sql = "DELETE FROM chat WHERE state = @STATE";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't prepare the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return;
    }
    
    // Prepare statement
    sqlite3_bind_int(sqlStatement, 1, (int)MessageStateExpired);
    
    if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        sqlite3_finalize(sqlStatement);
        return;
    }
    
    sqlite3_finalize(sqlStatement);
}


- (void)refreshSipMessage
{
    NSMutableString *sipMessageGen = [NSMutableString string];
    [sipMessageGen appendFormat:@"TYPE:%@;", [Message messageTypeToString:self.messageType]];
    [sipMessageGen appendFormat:@"CHAT_ID:%@;", [self chatId]];
    [sipMessageGen appendFormat:@"REF_CHAT_ID:%@;", [self refChatId]];
    [sipMessageGen appendFormat:@"EXPIRY_TIME:%@;", [self expiryTime]];
    [sipMessageGen appendFormat:@"MESSAGE:%@", [self text]];

    self.sipMessage = sipMessageGen;
}

+ (NSString *)messageDirectionToString:(MessageDirection)messageDirection
{
    NSString *messageDirectionString;
    
    switch ((MessageDirection)messageDirection) {
        case NoMessage:
            messageDirectionString = @"NoMessage";
            break;
        case IncomingMessage:
            messageDirectionString = @"Incoming";
            break;
        case OutgoingMessage:
            messageDirectionString = @"Outgoing";
            break;
    }
    
    return messageDirectionString;
}

+ (NSString *)messageTypeToString:(MessageType)messageType
{
    NSString *messageTypeToString;
    
    switch ((MessageType)messageType) {
        case UnknownMessage:
            messageTypeToString = @"UNK";
            break;
        case AckMessage:
            messageTypeToString = @"ACK";
            break;
        case TextMessage:
            messageTypeToString = @"TXT";
            break;
        case OpenedMessage:
            messageTypeToString = @"OPN";
            break;
    }
    
    return messageTypeToString;
}

+ (NSString *)messageStateToString:(MessageState)messageState
{
    NSString *messageStateToString;
    
    switch ((MessageState)messageState) {
        case MessageStateIdle:
            messageStateToString = NSLocalizedString(@"Idle", nil);
            break;
        case MessageStateInProgress:
            messageStateToString = NSLocalizedString(@"In Progress", nil);
            break;
        case MessageStateDelivered:
            messageStateToString = NSLocalizedString(@"Delivered", nil);
            break;
        case MessageStateNotDelivered:
            messageStateToString = NSLocalizedString(@"Not Delivered", nil);
            break;
        case MessageStateReceived:
            messageStateToString = NSLocalizedString(@"Received", nil);
            break;
        case MessageStateNotReceived:
            messageStateToString = NSLocalizedString(@"No feedback", nil);
            break;
        case MessageStateWaitingtoOpen:
            messageStateToString = NSLocalizedString(@"Waiting to Open", nil);
            break;
        case MessageStateOpened:
            messageStateToString = NSLocalizedString(@"Seen", nil);
            break;
        case MessageStateExpired:
            messageStateToString = NSLocalizedString(@"Expired", nil);
            break;
    }
    
    return messageStateToString;
}

- (NSString *)description {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    return [NSString stringWithFormat:@"chatId           : %@\n\
            refChatId        : %@\n\
            email            : [%@]\n\
            firstName        : [%@]\n\
            lastName         : [%@]\n\
            fullName         : [%@]\n\
            image            : %@\n\
            hasUnreadMessages: %@\n\
            messageDirection : %@\n\
            messageType      : %@\n\
            text             : [%@]\n\
            sipMessage       : [%@]\n\
            receivedDate     : %@\n\
            openedDate       : %@\n\
            state            : %@\n\
            expiryTime       : %@\n\
            indexPath        : %@",
            [self chatId],
            [self refChatId],
            [self email],
            [self firstName],
            [self lastName],
            [self fullName],
            [self image]?@"Found":@"Not found",
            [self hasUnreadMessages]?@"YES":@"NO",
            [Message messageDirectionToString:self.messageDirection],
            [Message messageTypeToString:self.messageType],
            [self text],
            [self sipMessage],
            [formatter stringFromDate:[self receivedDate]],
            [formatter stringFromDate:[self openedDate]],
            [Message messageStateToString:self.messageState],
            [self expiryTime],
            [[self indexPath] description]];
}

@end
