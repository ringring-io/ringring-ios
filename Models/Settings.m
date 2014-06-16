//
//  Settings.m
//  ringring.io
//
//  Created by Peter Kosztolanyi on 15/02/2014.
//
//

#import "Settings.h"



@implementation Settings


+ (BOOL)isFirstAlreadyLaunched {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"FirstAlreadyLaunched"];
}

+ (void)setFirstAlreadyLaunched:(BOOL)firstAlreadyLaunched {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:firstAlreadyLaunched forKey:@"FirstAlreadyLaunched"];
    
    [defaults synchronize];
}

+ (BOOL)isAutoClearCallHistoryEnabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"AutoClearCallHistoryEnabled"];;
}

+ (ClearInterval)autoClearCallHistory {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    ClearInterval autoClearCallHistory = [defaults integerForKey:@"AutoClearCallHistory"];
    
    // Set default value if not defined
    if (autoClearCallHistory == NotDefined)
        autoClearCallHistory = OneMinute;
    
    return autoClearCallHistory;
}

+ (BOOL)isAutoClearChatHistoryEnabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"AutoClearChatHistoryEnabled"];
}

+ (ClearInterval)autoClearChatHistory {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    ClearInterval autoClearChatHistory = [defaults integerForKey:@"AutoClearChatHistory"];
    
    // Set default value if not defined
    if (autoClearChatHistory == NotDefined)
        autoClearChatHistory = FiveMinutes;
    
    return autoClearChatHistory;
}

+ (void)setAutoClearCallHistoryEnabled:(BOOL)autoClearCallHistoryEnabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:autoClearCallHistoryEnabled forKey:@"AutoClearCallHistoryEnabled"];
    
    [defaults synchronize];
}

+ (void)setAutoClearCallHistory:(ClearInterval) clearInterval {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:clearInterval forKey:@"AutoClearCallHistory"];
    
    [defaults synchronize];
}

+ (void)setAutoClearChatHistoryEnabled:(BOOL)autoClearChatHistoryEnabled {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:autoClearChatHistoryEnabled forKey:@"AutoClearChatHistoryEnabled"];
    
    [defaults synchronize];
}

+ (void)setAutoClearChatHistory:(ClearInterval) clearInterval {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:clearInterval forKey:@"AutoClearChatHistory"];
    
    [defaults synchronize];
}

+ (NSString *)clearIntervalToString:(ClearInterval)clearInterval {
    NSString *clearIntervalToString;
    
    switch ((ClearInterval)clearInterval) {
        case NotDefined:
            clearIntervalToString = NSLocalizedString(@"NOT_DEFINED", nil);
            break;
        case OneMinute:
            clearIntervalToString = NSLocalizedString(@"1_MINUTE", nil);
            break;
        case FiveMinutes:
            clearIntervalToString = NSLocalizedString(@"5_MINUTES", nil);
            break;
        case FiveteenMinutes:
            clearIntervalToString = NSLocalizedString(@"15_MINUTES", nil);
            break;
        case ThirtyMinutes:
            clearIntervalToString = NSLocalizedString(@"30_MINUTES", nil);
            break;
        case OneHour:
            clearIntervalToString = NSLocalizedString(@"1_HOUR", nil);
            break;
        case TwelveHours:
            clearIntervalToString = NSLocalizedString(@"12_HOURS", nil);
            break;
        case OneDay:
            clearIntervalToString = NSLocalizedString(@"1_DAY", nil);
            break;
    }
    
    return clearIntervalToString;
}


+ (NSTimeInterval)clearIntervalToTimeInterval:(ClearInterval)clearInterval
{
    int clearIntervalToSeconds;
    
    switch ((ClearInterval)clearInterval) {
        case NotDefined:
            clearIntervalToSeconds = 0;
            break;
        case OneMinute:
            clearIntervalToSeconds = 60;
            break;
        case FiveMinutes:
            clearIntervalToSeconds = 300;
            break;
        case FiveteenMinutes:
            clearIntervalToSeconds = 900;
            break;
        case ThirtyMinutes:
            clearIntervalToSeconds = 1800;
            break;
        case OneHour:
            clearIntervalToSeconds = 3600;
            break;
        case TwelveHours:
            clearIntervalToSeconds = 43200;
            break;
        case OneDay:
            clearIntervalToSeconds = 86400;
            break;
    }
    
    return clearIntervalToSeconds;
}

+ (NSString *)description {
    return [NSString stringWithFormat:@"isFirstAlreadyLaunched       : %d\n\
            isAutoClearCallHistoryEnabled: %d\n\
            autoClearCallHistory         : [%@]\n\
            isAutoClearChatHistoryEnabled: %d\n\
            autoClearChatHistory         : [%@]",
            [self isFirstAlreadyLaunched],
            [self isAutoClearCallHistoryEnabled],
            [Settings clearIntervalToString:self.autoClearCallHistory],
            [self isAutoClearChatHistoryEnabled],
            [Settings clearIntervalToString:self.autoClearChatHistory]];
}


@end
