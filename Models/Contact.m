//
//  ContactPerson.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 13/01/2014.
//
//

#import "Contact.h"
#import <AddressBook/AddressBook.h>
#import "AddressBookMap.h"
#import "LinphoneHelper.h"

#import "RestKit/RestKit.h"
#import "MappingProvider.h"
#import "Status.h"
#import "User.h"


@implementation Contact

@synthesize email;
@synthesize firstName;
@synthesize lastName;
@synthesize fullName;
@synthesize image;
@synthesize hasUnreadMessages;
@synthesize isActivated;
@synthesize isLoggedIn;
@synthesize statusRefreshedAt;


// Init new contact from parameter values
- (id)initWithEmail:(NSString *)anEmail withFirstName:(NSString *)aFirstName withLastName:(NSString *)aLastName withImage:(UIImage *)anImage;
{
    self = [super init];
    if (self) {
        
        // Create new contact from the parameter values
        self.email = anEmail;
        self.firstName = aFirstName?aFirstName:@"";
        self.lastName = aLastName?aLastName:@"";
        self.fullName = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
        // Clear empty space fullnames
        if ([self.fullName isEqualToString:@" "]) self.fullName = @"";

        self.image = anImage?anImage:[UIImage imageNamed:@"contacts_avatar_default.png"];
        self.hasUnreadMessages = NO;
        self.isActivated = NO;
        self.isLoggedIn = NO;
        self.statusRefreshedAt = [[NSDate date] dateByAddingTimeInterval:-120];
    }
    
    return self;
}

// Copy an existing contact
- (id)initWithContact:(Contact *)aContact
{
    self = [super init];
    if (self) {
        
        self.email = aContact.email;
        self.firstName = aContact.firstName?aContact.firstName:@"";
        self.lastName = aContact.lastName?aContact.lastName:@"";
        self.fullName = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
        // Clear empty space fullnames
        if ([self.fullName isEqualToString:@" "]) self.fullName = @"";

        self.image = aContact.image?aContact.image:[UIImage imageNamed:@"contacts_avatar_default.png"];
        self.hasUnreadMessages = NO;
        self.isActivated = NO;
        self.isLoggedIn = NO;
        self.statusRefreshedAt = [[NSDate date] dateByAddingTimeInterval:-120];
    }
    
    return self;
}

// Init new contact with default values
- (id)initWithDefault:(NSString *)anEmail
{
    self = [super init];
    if (self) {
        self.email = anEmail;
        self.firstName = NSLocalizedString(@"Unknown", nil);
        self.lastName = NSLocalizedString(@"Unknown", nil);
        self.fullName = NSLocalizedString(@"Unknown", nil);
        self.image = [UIImage imageNamed:@"contacts_avatar_default.png"];
        self.hasUnreadMessages = NO;
        self.isActivated = NO;
        self.isLoggedIn = NO;
        self.statusRefreshedAt = [[NSDate date] dateByAddingTimeInterval:-120];
    }
    
    return self;
}

// Contact details to string
- (NSString *)description {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    
    return [NSString stringWithFormat:@"email            : [%@]\n\
            firstName        : [%@]\n\
            lastName         : [%@]\n\
            fullName         : [%@]\n\
            image            : %@\n\
            hasUnreadMessages: %@\n\
            isActivated      : %@\n\
            isLoggedIn       : %@\n\
            statusRefreshedAt: %@",
            [self email],
            [self firstName],
            [self lastName],
            [self fullName],
            [self image]?@"Found":@"Not found",
            [self hasUnreadMessages]?@"YES":@"NO",
            [self isActivated]?@"YES":@"NO",
            [self isLoggedIn]?@"YES":@"NO",
            [formatter stringFromDate:[self statusRefreshedAt]]];
}

@end
