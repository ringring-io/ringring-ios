//
//  ContactLog.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 01/02/2014.
//
//

#import "Contact.h"
#import "Message.h"
#import "LinphoneManager.h"

typedef enum RecentType : NSUInteger {
    RecentCall,
    RecentMessage
} RecentType;

@interface RecentContact : Contact

@property (nonatomic) enum RecentType recentType;
@property (nonatomic, assign) LinphoneCallDir  *callDirection;
@property (nonatomic, assign) LinphoneCallStatus *callStatus;
@property (nonatomic, assign) int callDuration;
@property (readwrite) enum MessageDirection messageDirection;
@property (nonatomic, retain) NSDate *recentDate;

- (id)initWithCallLog:(LinphoneCallLog *)callLog withContact:(Contact *)aContact;
- (id)initWithMessageLog:(Message *)message withContact:(Contact *)aContact;

- (NSString *)recentTypeToString;
- (NSString *)callDirectionToString;
- (NSString *)callStatusToString;
- (NSString *)description;

@end
