//
//  Settings.h
//  zirgoo
//
//  Created by Peter Kosztolanyi on 15/02/2014.
//
//

#import <Foundation/Foundation.h>

typedef enum Setting : NSUInteger {
    AutoClearCallHistory,
    AutoClearChatHistory
} Setting;

typedef enum ClearInterval : NSUInteger {
    NotDefined,
    FiveMinutes,
    FiveteenMinutes,
    ThirtyMinutes,
    OneHour,
    TwelveHours,
    OneDay
} ClearInterval;

@interface Settings : NSObject

+ (BOOL)isFirstAlreadyLaunched;
+ (void)setFirstAlreadyLaunched:(BOOL)firstAlreadyLaunched;

+ (BOOL)isAutoClearCallHistoryEnabled;
+ (ClearInterval)autoClearCallHistory;

+ (BOOL)isAutoClearChatHistoryEnabled;
+ (ClearInterval)autoClearChatHistory;

+ (void)setAutoClearCallHistoryEnabled:(BOOL) autoClearCallHistoryEnabled;
+ (void)setAutoClearCallHistory:(ClearInterval) clearInterval;

+ (void)setAutoClearChatHistoryEnabled:(BOOL) autoClearChatHistoryEnabled;
+ (void)setAutoClearChatHistory:(ClearInterval) clearInterval;

+ (NSString *)settingToString:(Setting)setting;
+ (NSString *)clearIntervalToString:(ClearInterval)clearInterval;
+ (NSTimeInterval)clearIntervalToTimeInterval:(ClearInterval)clearInterval;

+ (NSString *)description;

@end
