//
//  RingringMessage.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 27/05/2014.
//
//

#import "RingringMessage.h"

@implementation RingringMessage

@synthesize ringringMessageString;

@synthesize longText;
@synthesize cause;
@synthesize text;
@synthesize ringringText;

- (id)initWithRingringMessageString:(NSString *)aRingringMessageString
{
    self.ringringMessageString = aRingringMessageString;
    
    // Sample sipMessage: "TEXT;cause=99;text="TEXT"
    NSArray *ringringMessageComponents = [aRingringMessageString componentsSeparatedByString:@";"];
    NSString *ringringMessageComponent;
    NSRange range;
    
    if ([ringringMessageComponents count] == 3) {
        
        // Extract longText
        ringringMessageComponent = [ringringMessageComponents objectAtIndex:0];
        self.longText = ringringMessageComponent;
    
        // Extract Cause
        ringringMessageComponent = [ringringMessageComponents objectAtIndex:1];
        range = [ringringMessageComponent rangeOfString:@"="];
        if (range.length > 0) {
            NSString *sCause = [[ringringMessageComponents objectAtIndex:1] substringFromIndex:range.location + 1];
            NSScanner *scannerCause = [NSScanner scannerWithString:sCause];
            int dCause;
    
            if ([scannerCause scanInt:&dCause] && scannerCause.scanLocation == sCause.length) {
                self.cause = [NSNumber numberWithInt:dCause];
            }
        }

        // Extract Text
        ringringMessageComponent = [ringringMessageComponents objectAtIndex:2];
        range = [ringringMessageComponent rangeOfString:@"="];
        if (range.length > 0)
            self.text = [ringringMessageComponent substringFromIndex:range.location + 1];
    }
    
    // Translate readable text massage
    if (self.text) {
        if ([self.text isEqualToString:@"\"USER_BUSY\""])
            self.ringringText = NSLocalizedString(@"User is Busy", nil);
        else {
            self.ringringText = self.text;
        }
    }
    else {
        self.ringringText = NSLocalizedString(@"Try again later", nil);
    }
    
    return self;
}

// RingringMessage details to string
- (NSString *)description {    
    
    return [NSString stringWithFormat:@"ringringMessagString : [%@]\n\
            longText            : [%@]\n\
            cause               : [%@]\n\
            text                : [%@]\n\
            ringringText        : [%@]",
            [self ringringMessageString],
            [self longText],
            [self cause],
            [self text],
            [self ringringText]];
}

@end
