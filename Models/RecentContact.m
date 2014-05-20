//
//  RecentContact.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 01/02/2014.
//
//

#import "RecentContact.h"
#import "LinphoneManager.h"
#import "LinphoneHelper.h"
#import "AddressBookMap.h"

@implementation RecentContact

@synthesize recentType;
@synthesize callDirection;
@synthesize callStatus;
@synthesize callDuration;
@synthesize messageDirection;
@synthesize recentDate;



- (id)initWithCallLog:(LinphoneCallLog *)callLog withContact:(Contact *)aContact
{
    Contact *contact = nil;
 
    // Get email from call log
    NSString *email = [LinphoneHelper emailFromCallLog:callLog];

    // Contact is incoming parameter
    if (aContact) {
        contact = aContact;
    }
    // Contact is not defined; try to get it from the addressbook by email
    else {
        contact = [AddressBookMap getContactWithEmail:email];
    }
    
    // Contact found; clone the result contact
    if (contact) {
        self = [super initWithContact:contact];
    }
    // Still no contact; create adefault contact
    else {
        self = [super initWithDefault:email];
    }
    
    // Add Recent properties
    if (self && callLog) {
        self.recentType = RecentCall;
        self.callDirection = (LinphoneCallDir *)linphone_call_log_get_dir(callLog);
        self.callStatus = (LinphoneCallStatus *)linphone_call_log_get_status(callLog);
        self.callDuration = linphone_call_log_get_duration(callLog);
        self.messageDirection = NoMessage;
        self.recentDate = [NSDate dateWithTimeIntervalSince1970:linphone_call_log_get_start_date(callLog)];
    }
    
    return self;
}

- (id)initWithMessageLog:(Message *)message withContact:(Contact *)aContact;
{
    Contact *contact = nil;
    
    // Get email from message log
    NSString *email = message.email;
    
    // Contact is incoming parameter
    if (aContact) {
        contact = aContact;
    }
    // Contact is not defined; try to get it from the addressbook by email
    else {
        contact = [AddressBookMap getContactWithEmail:email];
    }
    
    // Contact found; clone the result contact
    if (contact) {
        self = [super initWithContact:contact];
    }
    // Still no contact; create default contact
    else {
        self = [super initWithDefault:email];
    }
    
    // Add Recent properties
    if (self && message) {
        self.recentType = RecentMessage;
        self.callDirection = nil;
        self.callStatus = nil;
        self.callDuration = 0;
        self.messageDirection = message.messageDirection;
        self.recentDate = message.receivedDate;
        self.hasUnreadMessages = message.hasUnreadMessages;
    }
    
    return self;
}

- (NSString *)recentTypeToString
{
    NSString *recentTypeString;
    
    switch ((RecentType)recentType) {
        case RecentCall:
            recentTypeString = NSLocalizedString(@"Call", nil);
            break;
        case RecentMessage:
            recentTypeString = NSLocalizedString(@"Message",  nil);
            break;
    }
    
    return recentTypeString;
}

- (NSString *)callDirectionToString
{
    NSString *callDirectionString;
    
    if (recentType == RecentCall) {
        switch ((LinphoneCallDir)callDirection) {
            case LinphoneCallOutgoing:
                callDirectionString = NSLocalizedString(@"Outgoing", nil);
                break;
            case LinphoneCallIncoming:
                callDirectionString = NSLocalizedString(@"Incoming", nil);
                break;
        }
    }
    
    return callDirectionString;
}

- (NSString *)callStatusToString
{
    NSString *callStatusString;
    
    if (recentType == RecentCall) {
        switch ((LinphoneCallStatus)callStatus) {
            case LinphoneCallAborted:
                callStatusString = NSLocalizedString(@"Aborted", nil);
                break;

            case LinphoneCallDeclined:
                callStatusString = NSLocalizedString(@"Declined", nil);
                break;

            case LinphoneCallMissed:
                callStatusString = NSLocalizedString(@"Missed", nil);
                break;

            case LinphoneCallSuccess:
                callStatusString = NSLocalizedString(@"Success", nil);
                break;
        }
    }
    
    return callStatusString;
}

- (NSString *)messageDirectionToString
{
    NSString *messageDirectionString;
    
    if (recentType == RecentMessage) {
        switch ((MessageDirection)messageDirection) {
            case NoMessage:
                messageDirectionString = NSLocalizedString(@"NoMessage", nil);
                break;
            case OutgoingMessage:
                messageDirectionString = NSLocalizedString(@"Outgoing", nil);
                break;
            case IncomingMessage:
                messageDirectionString = NSLocalizedString(@"Incoming", nil);
                break;
        }
    }
    
    return messageDirectionString;
}


- (NSString *)description {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    return [NSString stringWithFormat:@"email            : [%@]\n\
            recentType       : [%@]\n\
            firstName        : [%@]\n\
            lastName         : [%@]\n\
            fullName         : [%@]\n\
            image            : %@\n\
            hasUnreadMessages: %@\n\
            isActivated      : %@\n\
            isLoggedIn       : %@\n\
            statusRefreshedAt: %@\n\
            callDirection    : %@\n\
            callStatus       : %@\n\
            callDuration     : %d\n\
            messageDirection : %@\n\
            recentDate       : %@",
            [self email],
            [self recentTypeToString],
            [self firstName],
            [self lastName],
            [self fullName],
            [self image]?@"Found":@"Not found",
            [self hasUnreadMessages]?@"YES":@"NO",
            [self isActivated]?@"YES":@"NO",
            [self isLoggedIn]?@"YES":@"NO",
            [formatter stringFromDate:[self statusRefreshedAt]],
            [self callDirectionToString],
            [self callStatusToString],
            callDuration,
            [self messageDirectionToString],
            [formatter stringFromDate:[self recentDate]]];
}

@end
