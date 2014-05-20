//
//  LinphoneHelper.m
//  zirgoo
//
//  Created by Peter Kosztolanyi on 22/01/2014.
//
//

#import <CommonCrypto/CommonDigest.h>

#import "LinphoneHelper.h"
#import "LinphoneManager.h"



@interface LinphoneHelper ()

@end



@implementation LinphoneHelper

# pragma mark - Helper Functions

// I there active registraion
+ (BOOL)isRegistered
{
    BOOL isRegistered = false;
    LinphoneProxyConfig* proxyCfg = NULL;
    
    if([LinphoneManager isLcReady])
        linphone_core_get_default_proxy([LinphoneManager getLc], &proxyCfg);
    
    if(proxyCfg != nil)
        isRegistered = true;
        
    return isRegistered;
}

// Send registration request to the SIP server
+ (void)registerSip:(NSString*)email withPassword:(NSString*)password
{
    // Convert email to sip friendly usernames
    NSString *sipUser = [self emailToSipUser:email];
    
    // Register to SIP server
    [self addProxyConfig:sipUser
                password:password
                  domain:[[LinphoneManager instance] lpConfigStringForKey:@"domain" forSection:@"sip"]
                  server:[[LinphoneManager instance] lpConfigStringForKey:@"proxy" forSection:@"sip"]];
}

// Send unregistration request to the SIP server
+ (void)unregisterSip
{
    LinphoneProxyConfig* proxyCfg = NULL;
    
    if([LinphoneManager isLcReady])
        linphone_core_get_default_proxy([LinphoneManager getLc], &proxyCfg);
    
    if(proxyCfg != nil) {
        linphone_proxy_config_edit(proxyCfg);
        linphone_proxy_config_enable_register(proxyCfg, false);
        linphone_proxy_config_done(proxyCfg);

    }
}

// Clear all proxy configuration and authentication settings. This does not unregister from the server
+ (void)clearProxyConfig {
	linphone_core_clear_proxy_config([LinphoneManager getLc]);
	linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}

// Get the registered SIP user name
+ (NSString *)registeredSipUser
{
    NSString *registeredSipUser;
    LinphoneAuthInfo *ai;
    
    const MSList *elem = linphone_core_get_auth_info_list([LinphoneManager getLc]);
    if (elem && (ai=(LinphoneAuthInfo*)elem->data)) {
        if (linphone_auth_info_get_username(ai) != nil) {
        
            registeredSipUser = [NSString stringWithUTF8String:linphone_auth_info_get_username(ai)];
        }
    }
    
    return registeredSipUser;
}

// Get the registered email address
+ (NSString *)registeredEmail
{
    return [self sipUserToEmail:[self registeredSipUser]];
}

// Validate email address
+ (BOOL)isValidEmail:(NSString *)email
{
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".+@.+\\.[A-Za-z]{2}[A-Za-z]*"];
    
    return [emailTest evaluateWithObject:email];
}

// Convert SIP user name to valid email address
+ (NSString *)sipUserToEmail:(NSString *)sipUser
{
    NSString *email;
    
    email = [sipUser stringByReplacingOccurrencesOfString:@"_AT_"
                                               withString:@"@"];
    
    email = [email stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    email = [email stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return email;
}

// Convert email address to SIP user name
+ (NSString *)emailToSipUser:(NSString *)email
{
    return [email stringByReplacingOccurrencesOfString:@"@"
                                            withString:@"_AT_"];
}



# pragma mark - Helpmates

// Create new proxy configuration and send registration request
+ (void)addProxyConfig:(NSString*)username password:(NSString*)password domain:(NSString*)domain server:(NSString*)server {
    [self clearProxyConfig];
    if(server == nil) {
        server = domain;
    }
	const char* identity = [[NSString stringWithFormat:@"sip:%@@%@", username, domain] UTF8String];
	LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config([LinphoneManager getLc]);
	LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String], NULL, [password UTF8String], NULL, NULL, NULL);
	linphone_proxy_config_set_identity(proxyCfg, identity);
	linphone_proxy_config_set_server_addr(proxyCfg, [server UTF8String]);
    if([server compare:domain options:NSCaseInsensitiveSearch] != 0) {
        linphone_proxy_config_set_route(proxyCfg, [server UTF8String]);
    }

    
    [self setDefaultSettings:proxyCfg];
    linphone_proxy_config_enable_register(proxyCfg, true);
    
    linphone_core_add_proxy_config([LinphoneManager getLc], proxyCfg);
	linphone_core_set_default_proxy([LinphoneManager getLc], proxyCfg);
	linphone_core_add_auth_info([LinphoneManager getLc], info);
}

// Set Linphone manager default settings
+ (void)setDefaultSettings:(LinphoneProxyConfig*)proxyCfg {
    BOOL pushnotification = [[LinphoneManager instance] lpConfigBoolForKey:@"push_notification" forSection:@"app"];
    [[LinphoneManager instance] lpConfigSetBool:pushnotification forKey:@"pushnotification_preference"];
    if(pushnotification) {
        [[LinphoneManager instance] addPushTokenToProxyConfig:proxyCfg];
    }
    int expires = (int)[[LinphoneManager instance] lpConfigIntForKey:@"expires" forSection:@"sip"];
    linphone_proxy_config_expires(proxyCfg, expires);
    
    NSString* transport = [[LinphoneManager instance] lpConfigStringForKey:@"transport" forSection:@"sip"];
    LinphoneCore *lc = [LinphoneManager getLc];
    LCSipTransports transportValue={0};
	if (transport!=nil) {
		if (linphone_core_get_sip_transports(lc, &transportValue)) {
			[self logc:LinphoneLoggerError format:"cannot get current transport"];
		}
		// Only one port can be set at one time, the others's value is 0
		if ([transport isEqualToString:@"tcp"]) {
			transportValue.tcp_port=transportValue.tcp_port|transportValue.udp_port|transportValue.tls_port;
			transportValue.udp_port=0;
            transportValue.tls_port=0;
		} else if ([transport isEqualToString:@"udp"]){
			transportValue.udp_port=transportValue.tcp_port|transportValue.udp_port|transportValue.tls_port;
			transportValue.tcp_port=0;
            transportValue.tls_port=0;
		} else if ([transport isEqualToString:@"tls"]){
			transportValue.tls_port=transportValue.tcp_port|transportValue.udp_port|transportValue.tls_port;
			transportValue.tcp_port=0;
            transportValue.udp_port=0;
		} else {
			[self logc:LinphoneLoggerError format:"unexpected transport [%s]",[transport cStringUsingEncoding:[NSString defaultCStringEncoding]]];
		}
		if (linphone_core_set_sip_transports(lc, &transportValue)) {
			[self logc:LinphoneLoggerError format:"cannot set transport"];
		}
	}
    
    BOOL ice = [[LinphoneManager instance] lpConfigBoolForKey:@"ice" forSection:@"net"];
    [[LinphoneManager instance] lpConfigSetBool:ice forKey:@"ice_preference"];
    
    NSString* stun = [[LinphoneManager instance] lpConfigStringForKey:@"stun" forSection:@"net"];
    [[LinphoneManager instance] lpConfigSetString:stun forKey:@"stun_preference"];
    
    if ([stun length] > 0){
        linphone_core_set_stun_server(lc, [stun UTF8String]);
        if(ice) {
            linphone_core_set_firewall_policy(lc, LinphonePolicyUseIce);
        } else {
            linphone_core_set_firewall_policy(lc, LinphonePolicyUseStun);
        }
    } else {
        linphone_core_set_stun_server(lc, NULL);
        linphone_core_set_firewall_policy(lc, LinphonePolicyNoFirewall);
    }
}

+ (NSString *)emailFromCallLog:(LinphoneCallLog *)callLog
{
    NSString *sipUser = NSLocalizedString(@"Unkown", nil);
    
    // Get contact sip username from the call log
    if (callLog) {
        LinphoneAddress *addr;
        LinphoneCallDir *callDirection = (LinphoneCallDir *)linphone_call_log_get_dir(callLog);
        
        // Get contact address
        switch ((LinphoneCallDir)callDirection) {
            case LinphoneCallOutgoing:
                addr = linphone_call_log_get_to(callLog);
                break;
            case LinphoneCallIncoming:
                addr = linphone_call_log_get_from(callLog);
                break;
        }
        
        sipUser = [NSString stringWithFormat:@"%s", linphone_address_get_username(addr)];
    }
    
    // Convert SIP user to email
    return [LinphoneHelper sipUserToEmail:sipUser];
}

+ (NSString *)dateToString:(NSDate *)date {
    NSString *dateString;
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MMM"];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    
    // Get today date
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    
    // Get yesterday date
    components = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate dateWithTimeIntervalSinceNow:-86400]];
    NSDate *yesterday = [cal dateFromComponents:components];
    
    // Get call start date
    components = [[NSCalendar currentCalendar] components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
    NSDate *callStartDate = [cal dateFromComponents:components];
    
    // Use time format for today
    if ([callStartDate isEqualToDate:today]) {
        dateString = [timeFormatter stringFromDate:date];
    }
    
    // Use 'yesterday' for yestarday
    else if ([callStartDate isEqualToDate:yesterday]) {
        dateString = NSLocalizedString(@"Yesterday", nil);
    }
    
    // Use date format otherwise
    else {
        dateString = [dateFormatter stringFromDate:date];
    }
    
    return dateString;
}

+ (UIImage *)imageAsCircle:(UIImage *)anImage
{
    CGRect imgRect = CGRectMake(0.0f,
                                0.0f,
                                anImage.size.width,
                                anImage.size.height);
    
    UIGraphicsBeginImageContextWithOptions(imgRect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGContextRestoreGState(context);
    
    UIBezierPath *imgPath = [UIBezierPath bezierPathWithOvalInRect:imgRect];
    [imgPath addClip];
    
    [anImage drawInRect:imgRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (void)updateApplicationBadgeNumber {
    int count = 0;
    count += linphone_core_get_missed_calls_count([LinphoneManager getLc]);
    
    //count += [ChatModel unreadMessages];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
}

+ (NSString *)MD5String:(NSString *)string
{
    const char *cstr = [string UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (int)strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

+ (void)log:(LinphoneLoggerSeverity) severity format:(NSString *)format,... {
    /*
    va_list args;
	va_start (args, format);
    NSString *str = [[NSString alloc] initWithFormat: format arguments:args];
    if(severity <= LinphoneLoggerDebug) {
        ms_debug("%s", [str UTF8String]);
    } else  if(severity <= LinphoneLoggerLog) {
        ms_message("%s", [str UTF8String]);
    } else if(severity <= LinphoneLoggerWarning) {
        ms_warning("%s", [str UTF8String]);
    } else if(severity <= LinphoneLoggerError) {
        ms_error("%s", [str UTF8String]);
    } else if(severity <= LinphoneLoggerFatal) {
        ms_fatal("%s", [str UTF8String]);
    }
    va_end (args);
    */
}

+ (void)logc:(LinphoneLoggerSeverity) severity format:(const char *)format,... {
    /*va_list args;
	va_start (args, format);
    if(severity <= LinphoneLoggerDebug) {
        ortp_logv(ORTP_DEBUG, format, args);
    } else if(severity <= LinphoneLoggerLog) {
        ortp_logv(ORTP_MESSAGE, format, args);
    } else if(severity <= LinphoneLoggerWarning) {
        ortp_logv(ORTP_WARNING, format, args);
    } else if(severity <= LinphoneLoggerError) {
        ortp_logv(ORTP_ERROR, format, args);
    } else if(severity <= LinphoneLoggerFatal) {
        ortp_logv(ORTP_FATAL, format, args);
    }
	va_end (args);
    */
}



@end
