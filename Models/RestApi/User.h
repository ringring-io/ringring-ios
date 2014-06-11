//
//  User.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 23/02/2014.
//
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *activationCode;
@property (nonatomic) BOOL isActivated;
@property (nonatomic) BOOL isLoggedIn;

@end
