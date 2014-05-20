//
//  FastAddressBook.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 02/02/2014.
//
//

#import <UIKit/UIKit.h>

#import "LinphoneManager.h"
#import "LinphoneHelper.h"
#import "AddressBookMap.h"

static NSMutableDictionary *addressBookMap;

@implementation AddressBookMap


// Refresh the Fast AddressBookMap
+ (void)reload
{
    CFErrorRef error = NULL;
    addressBookMap = [[NSMutableDictionary alloc] init];
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);

    //boolean variable stands for directory access
    __block BOOL isaccess = NO;
    
    //ABAddressBookRequestAccessWithCompletion use to request access to address book data
    //this function is availabile in iOS 6.0
    
    //iOS >=6
    if(ABAddressBookRequestAccessWithCompletion != NULL) {
        //Create the semaphore, specifying the initial pool size
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        //ask to grand or deny access
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            isaccess = granted;
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    //iOS 5 or older
    else {
        isaccess = YES;
    }
    
    if (isaccess)
    {
        NSArray *allContacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
        
        // Sort contacts by first names
        CFArraySortValues((__bridge CFMutableArrayRef)(allContacts),
                          CFRangeMake(0, CFArrayGetCount((__bridge CFArrayRef)(allContacts))),
                          (CFComparatorFunction) ABPersonComparePeopleByName,
                          kABPersonSortByFirstName);

        for (CFIndex i = 0; i < ABAddressBookGetPersonCount(addressBook); i++) {
            ABRecordRef recordRef = (__bridge ABRecordRef)allContacts[i];
            
            // Loop through all emails
            ABMultiValueRef emails = ABRecordCopyValue(recordRef, kABPersonEmailProperty);
            for (CFIndex j = 0; j < ABMultiValueGetCount(emails); j++) {
                
                // Get contact details from AddressBook
                NSString *email = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emails, j);

                [addressBookMap setValue:(__bridge id)(recordRef)
                                  forKey:email];

            }
            CFRetain(recordRef);
        }
        
        CFRelease(addressBook);
    }
}


// Get all list of contacts from AddressBookMap
+ (NSMutableArray *)getContactList:(NSMutableArray *)emailList
{
    NSMutableArray *contactList = [[NSMutableArray alloc] init];

    // Create ABAddressBookRef only one time to improve performance
    CFErrorRef error = nil;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);

    // Foreach every email in the list
    for (id email in emailList) {
 
        // Get ABRecordRef from the pre-loaded AddressBookMap
        ABRecordRef aRecordRef = (__bridge ABRecordRef)([addressBookMap objectForKey:email]);
        
        // Get first and last names by ABRecordRef
        NSString *aFirstName = (__bridge_transfer NSString *)ABRecordCopyValue(aRecordRef, kABPersonFirstNameProperty);
        NSString *aLastName = (__bridge_transfer NSString *)ABRecordCopyValue(aRecordRef, kABPersonLastNameProperty);

        // To get the image correctly we need the original ABRecordRef
        UIImage *anImage = nil;
        ABRecordID recordId = ABRecordGetRecordID(aRecordRef);
        ABRecordRef origContactRef = ABAddressBookGetPersonWithRecordID(addressBookRef, recordId);
        
        // Get the image
        if (ABPersonHasImageData(origContactRef)) {
            anImage = [UIImage imageWithData:(__bridge_transfer NSData *)
                       ABPersonCopyImageDataWithFormat(origContactRef, kABPersonImageFormatThumbnail)];
            //ABPersonCopyImageData(aRecordRef)];
        }

        // Create a new contact
        Contact *contact = [[Contact alloc] initWithEmail:email
                                            withFirstName:aFirstName
                                             withLastName:aLastName
                                                withImage:anImage];
        
        // Put the new contact into the result array
        [contactList addObject:contact];
    }
    
    // Release ABAddressBookRef
    CFRelease(addressBookRef);
 
    return contactList;
}

// Get one specific contact from AddressBookMap
+ (Contact *)getContactWithEmail:(NSString *)email
{
    NSMutableArray *contactList = [[NSMutableArray alloc] init];
    [contactList addObject:email];
    
    NSMutableArray *contacts = [self getContactList:contactList];
    return [contacts objectAtIndex:0];
}

// Get every contacts from myContacts
+ (NSMutableArray *)getMyContacts
{
    NSMutableArray *myContacts = [NSMutableArray array];
    
    // Connect to database
    sqlite3* database = [[LinphoneManager instance] database];
    if(database == NULL) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Database not ready"];
        return myContacts;
    }
    
    // Select every message from the remote email address
    const char *sql = "SELECT id, contact_email, first_name, last_name FROM my_contacts ORDER BY contact_email ASC";
    sqlite3_stmt *sqlStatement;
    if (sqlite3_prepare_v2(database, sql, -1, &sqlStatement, NULL) != SQLITE_OK) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Can't execute the query: %s (%s)", sql, sqlite3_errmsg(database)];
        return myContacts;
    }
    
    int err;
    while ((err = sqlite3_step(sqlStatement)) == SQLITE_ROW) {
        Contact *contact = [[Contact alloc] initWithEmail:[NSString stringWithUTF8String: (const char*) sqlite3_column_text(sqlStatement, 0)]
                                            withFirstName:[NSString stringWithUTF8String: (const char*) sqlite3_column_text(sqlStatement, 1)]
                                             withLastName:[NSString stringWithUTF8String: (const char*) sqlite3_column_text(sqlStatement, 2)]
                                                withImage:nil];
        
        [myContacts addObject:contact];
    }
    
    if (err != SQLITE_DONE) {
        [LinphoneHelper logc:LinphoneLoggerError format:"Error during execution of query: %s (%s)", sql, sqlite3_errmsg(database)];
        return myContacts;
    }
    
    sqlite3_finalize(sqlStatement);
    
    return myContacts;
}

// Get every contacts from AddressBookMap
+ (NSMutableArray *)getAddressBookContacts:(NSMutableArray *)excludeContacts
{
    NSMutableArray *emailList = [[NSMutableArray alloc] init];
    for (id email in addressBookMap) {
        
        // Do not add email to the list if it's in the exclude list parameter
        bool excludeEmail = false;
        if (excludeContacts) {
            for (Contact *contact in excludeContacts) {
                
                if ([contact.email isEqualToString:email]) {
                    excludeEmail = true;
                }
                break;
            }
        }
        if (!excludeEmail) {
            [emailList addObject:email];
        }
    }
    
    return [self getContactList:emailList];
}

// Concat My Contacts and AddressBook Contacts
+ (NSMutableArray *)getAllContacts
{
    NSMutableArray *excludeContactList = [[NSMutableArray alloc] init];
    
    return [self getAddressBookContacts:excludeContactList];
}

// Get recent call contacts from AddressBookMap
+ (NSMutableArray *)getRecentCallContacts:(const MSList *)logList;
{
    const MSList *logListRef;
    NSMutableArray *emailList = [[NSMutableArray alloc] init];
    
    // Get a list of emails from logs
    logListRef = logList;
    while(logListRef != NULL) {
        LinphoneCallLog *callLog = (LinphoneCallLog *) logListRef->data;
        NSString *email = [LinphoneHelper emailFromCallLog:callLog];
        
        [emailList addObject:email];
        logListRef = ms_list_next(logListRef);
    }
    
    // Fast load contact details from AddressBookMap
    NSMutableArray *contactList = [self getContactList:emailList];
    
    // Create an array for the result recentContactList
    NSMutableArray *recentContactList = [[NSMutableArray alloc] init];
    
    // Foreach the contactList and populate the call log attributes
    logListRef = logList;
    for (id contact in contactList) {
        LinphoneCallLog *callLog = (LinphoneCallLog *) logListRef->data;
        RecentContact *recentContact = [[RecentContact alloc] initWithCallLog:callLog
                                                                  withContact:contact];
        
        [recentContactList addObject:recentContact];
        logListRef = ms_list_next(logListRef);
    }
    
    return recentContactList;
}

// Get recent message contacts from AddressBookMap
+ (NSMutableArray *)getRecentMessageConntacts:(NSMutableArray *)messageLogList
{
    NSMutableArray *emailList = [[NSMutableArray alloc] init];
    
    // Get a list of email from message logs
    for (Message *message in messageLogList) {
        [emailList addObject:message.email];
    }
    
    // Fast load contact details from AddressBookMap
    NSMutableArray *contactList = [self getContactList:emailList];
    
    // Create an array for the result recentContactList
    NSMutableArray *recentMessageContactList = [[NSMutableArray alloc] init];
    
    // Foreach the contactList and populate the message log attributes
    for (int i = 0; i < [contactList count]; i++) {
        Message *message = messageLogList[i];
        Contact *contact = contactList[i];
        
        RecentContact *recentMessageContact = [[RecentContact alloc] initWithMessageLog:message
                                                                     withContact:contact];
        [recentMessageContactList addObject:recentMessageContact];
        
    }
    
    return recentMessageContactList;
}

+ (NSMutableArray *)getRecentContacts:(const MSList *)logList withMessageLogList:(NSMutableArray *)messageLogList
{
    NSMutableArray *recentContacts = [[NSMutableArray alloc] init];
    
    // Add recent calls to the list
    for (RecentContact *recentCallContact in [self getRecentCallContacts:logList]) {
        [recentContacts addObject:recentCallContact];
    }
    
    // Add recent messages to the list
    for (RecentContact *recentMessageContact in [self getRecentMessageConntacts:messageLogList]) {
        [recentContacts addObject:recentMessageContact];
    }
    
    // Sort calls and messages into the same list by date
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"recentDate"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedRecentContacts = [recentContacts sortedArrayUsingDescriptors:sortDescriptors];
    
    return [sortedRecentContacts mutableCopy];
}

@end
