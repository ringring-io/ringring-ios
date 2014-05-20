//
//  StatusResult.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 26/02/2014.
//
//

#import <Foundation/Foundation.h>

@interface Status : NSObject

@property (nonatomic, retain) NSString *status;
@property (nonatomic) bool success;

- (id)initWithStatus:(NSString *)aStatus withSuccess:(NSString *)aSuccess;

@end
