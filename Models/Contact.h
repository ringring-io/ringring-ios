//
//  ContactPerson.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 13/01/2014.
//
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>



@interface Contact : NSObject

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *fullName;
@property (nonatomic, copy) UIImage *image;
@property (nonatomic) BOOL hasUnreadMessages;

@property (nonatomic) BOOL isActivated;
@property (nonatomic) BOOL isLoggedIn;
@property (nonatomic, retain) NSDate *statusRefreshedAt;

- (id)initWithEmail:(NSString *)anEmail withFirstName:(NSString *)aFirstName withLastName:(NSString *)aLastName withImage:(UIImage *)anImage;
- (id)initWithContact:(Contact *)contact;
- (id)initWithDefault:(NSString *)anEmail;

- (NSString *)description;

@end
