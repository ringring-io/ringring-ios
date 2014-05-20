//
//  MappingProvider.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 23/02/2014.
//
// 

#import "MappingProvider.h"
#import "RestKit/RestKit.h"

#import "Status.h"
#import "User.h"

@implementation MappingProvider

+ (RKMapping *)statusMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[Status class]];
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"status": @"status",
                                                  @"success": @"success"
                                                  }];
    
    return mapping;
}

+ (RKMapping *) userMapping {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[User class]];
    [mapping addAttributeMappingsFromDictionary:@{
                                                  @"email": @"email",
                                                  @"activationCode":@"activationCode",
                                                  @"isActivated":@"isActivated",
                                                  @"isLoggedIn":@"isLoggedIn"
                                                  }];
    
    return mapping;
}

@end
