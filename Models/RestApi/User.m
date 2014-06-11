//
//  User.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 24/02/2014.
//
//

#import "User.h"

@implementation User

- (NSString *)description {
    return [NSString stringWithFormat:@"email            : [%@]\n\
            activationCode   : [%@]\n\
            isActivated      : [%@]\n\
            isLoggedIn       : [%@]",
            [self email],
            [self activationCode],
            [self isActivated]?@"YES":@"NO",
            [self isLoggedIn]?@"YES":@"NO"];
}

@end
