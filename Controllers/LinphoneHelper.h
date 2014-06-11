//
//  LinphoneHelper.h
//  ringring.io
//
//  Created by Peter Kosztolanyi on 22/01/2014.
//
//

#import <Foundation/Foundation.h>
#import "LinphoneManager.h"

#define DYNAMIC_CAST(x, cls)                        \
({                                                 \
cls *inst_ = (cls *)(x);                        \
[inst_ isKindOfClass:[cls class]]? inst_ : nil; \
})


typedef enum _LinphoneLoggerSeverity {
    LinphoneLoggerLog = 0,
    LinphoneLoggerDebug,
    LinphoneLoggerWarning,
    LinphoneLoggerError,
    LinphoneLoggerFatal
} LinphoneLoggerSeverity;

@interface LinphoneHelper : NSObject

+ (BOOL)isRegistered;
+ (void)registerSip:(NSString*)email withPassword:(NSString*)password;
+ (void)unregisterSip;
+ (void)clearProxyConfig;

+ (NSString *)registeredSipUser;
+ (NSString *)registeredEmail;

+ (BOOL)isValidEmail:(NSString *)email;
+ (NSString *)sipUserToEmail:(NSString *)sipUser;
+ (NSString *)emailToSipUser:(NSString *)email;
+ (NSString *)emailFromCallLog:(LinphoneCallLog *)callLog;
+ (NSString *)dateToString:(NSDate *)date;
+ (UIImage *)imageAsCircle:(UIImage *)anImage;
+ (void)updateApplicationBadgeNumber;

+ (NSString *)MD5String:(NSString *)string;

+ (void)log:(LinphoneLoggerSeverity) severity format:(NSString *)format,...;
+ (void)logc:(LinphoneLoggerSeverity) severity format:(const char *)format,...;

@end
