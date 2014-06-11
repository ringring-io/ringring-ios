//
//  FastAddressBook.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 02/02/2014.
//
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#import "LinphoneManager.h"
#import "Contact.h"
#import "RecentContact.h"

@interface AddressBookMap : NSObject

+ (NSMutableArray *)getContactList:(NSMutableArray *)emailList;

+ (Contact *)getContactWithEmail:(NSString *)email;

+ (NSMutableArray *)getMyContacts;
+ (NSMutableArray *)getAddressBookContacts:(NSMutableArray *)excludeContacts;
+ (NSMutableArray *)getAllContacts;

+ (NSMutableArray *)getRecentCallContacts:(const MSList *)logList;
+ (NSMutableArray *)getRecentMessageConntacts:(NSMutableArray *)messageLogList;
+ (NSMutableArray *)getRecentContacts:(const MSList *)logList withMessageLogList:(NSMutableArray *)messageLogList;

+ (void)reload;

@end
