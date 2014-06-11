//
//  MappingProvider.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 23/02/2014.
//
//

#import <Foundation/Foundation.h>
#import "RestKit/RestKit.h"

@interface MappingProvider : NSObject

+ (RKMapping *) statusMapping;
+ (RKMapping *) userMapping;

@end
