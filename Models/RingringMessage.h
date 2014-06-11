//
//  RingringMessage.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 27/05/2014.
//
//

#import <Foundation/Foundation.h>

@interface RingringMessage : NSObject

@property (nonatomic, assign) NSString *ringringMessageString;

@property (nonatomic, assign) NSString *longText;
@property (nonatomic, assign) NSNumber *cause;
@property (nonatomic, assign) NSString *text;
@property (nonatomic, assign) NSString *ringringText;

- (id)initWithRingringMessageString:(NSString *)aRingringMessageString;

- (NSString *)description;

@end
