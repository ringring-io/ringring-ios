//
//  LinphoneMessage.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 27/05/2014.
//
//

#import "ZirgooMessage.h"

@implementation ZirgooMessage

@synthesize zirgooMessageString;

@synthesize longText;
@synthesize cause;
@synthesize text;
@synthesize zirgooText;

- (id)initWithZirgooMessageString:(NSString *)aZirgooMessageString
{
    self.zirgooMessageString = aZirgooMessageString;
    
    // Sample sipMessage: "TEXT;cause=99;text="TEXT"
    NSArray *zirgooMessageComponents = [aZirgooMessageString componentsSeparatedByString:@";"];
    NSString *zirgooMessageComponent;
    NSRange range;
    
    if ([zirgooMessageComponents count] == 3) {
        
        // Extract longText
        zirgooMessageComponent = [zirgooMessageComponents objectAtIndex:0];
        self.longText = zirgooMessageComponent;
    
        // Extract Cause
        zirgooMessageComponent = [zirgooMessageComponents objectAtIndex:1];
        range = [zirgooMessageComponent rangeOfString:@"="];
        if (range.length > 0) {
            NSString *sCause = [[zirgooMessageComponents objectAtIndex:1] substringFromIndex:range.location + 1];
            NSScanner *scannerCause = [NSScanner scannerWithString:sCause];
            int dCause;
    
            if ([scannerCause scanInt:&dCause] && scannerCause.scanLocation == sCause.length) {
                self.cause = [NSNumber numberWithInt:dCause];
            }
        }

        // Extract Text
        zirgooMessageComponent = [zirgooMessageComponents objectAtIndex:2];
        range = [zirgooMessageComponent rangeOfString:@"="];
        if (range.length > 0)
            self.text = [zirgooMessageComponent substringFromIndex:range.location + 1];
    }
    
    // Translate readable text massage
    if (self.text) {
        if ([self.text isEqualToString:@"\"USER_BUSY\""])
            self.zirgooText = NSLocalizedString(@"User is Busy", nil);
        else {
            self.zirgooText = self.text;
        }
    }
    else {
        self.zirgooText = NSLocalizedString(@"Try again later", nil);
    }
    
    return self;
}

// ZirgooMessage details to string
- (NSString *)description {    
    
    return [NSString stringWithFormat:@"zirgooMessagString : [%@]\n\
            longText            : [%@]\n\
            cause               : [%@]\n\
            text                : [%@]\n\
            zirgooText          : [%@]",
            [self zirgooMessageString],
            [self longText],
            [self cause],
            [self text],
            [self zirgooText]];
}

@end
