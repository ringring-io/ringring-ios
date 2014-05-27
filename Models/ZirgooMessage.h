//
//  LinphoneMessage.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 27/05/2014.
//
//

#import <Foundation/Foundation.h>

@interface ZirgooMessage : NSObject

@property (nonatomic, assign) NSString *zirgooMessageString;

@property (nonatomic, assign) NSString *longText;
@property (nonatomic, assign) NSNumber *cause;
@property (nonatomic, assign) NSString *text;
@property (nonatomic, assign) NSString *zirgooText;

- (id)initWithZirgooMessageString:(NSString *)aZirgooMessageString;

- (NSString *)description;

@end
