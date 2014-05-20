//
//  StatusResult.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 26/02/2014.
//
//

#import "Status.h"

@implementation Status

- (id)init
{
    self = [super init];
    
    return self;
}

- (id)initWithStatus:(NSString *)aStatus withSuccess:(NSString *)aSuccess
{
    self = [self init];
    if (self) {
        self.status = aStatus;
        self.success = aSuccess;
    }
    
    return self;
}

@end

