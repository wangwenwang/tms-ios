//
//  Tools.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "Tools.h"

@implementation Tools

+ (NSString *)getZipVersion {
    
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaults_ZipVersion_local_key];
}

+ (void)setZipVersion:(NSString *)version {
    
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:kUserDefaults_ZipVersion_local_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getServerAddress {
    
    return [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaults_Server_Address_key];
}

+ (void)setServerAddress:(NSString *)baseUrl {
    
    [[NSUserDefaults standardUserDefaults] setObject:baseUrl forKey:kUserDefaults_Server_Address_key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (int)compareVersion:(NSString *)server andLocati:(NSString *)locati {
    NSArray *servers = [server componentsSeparatedByString:@"."];
    NSArray *locatis = [locati componentsSeparatedByString:@"."];
    @try {
        int s = [servers[0] intValue] * 100 + [servers[1] intValue] * 10 + [servers[2] intValue] * 1;
        int l = [locatis[0] intValue] * 100 + [locatis[1] intValue] * 10 + [locatis[2] intValue] * 1;
        if(s == l) return 0;
        else return (s > l) ? 1 : -1;
    } @catch (NSException *exception) {
        return -2;
    }
}

+ (NSString *)getUnzipPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentpath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *unzipPath = [documentpath stringByAppendingPathComponent:@"/unzip"];
    return unzipPath;
}

+ (void)closeWebviewEdit:(UIWebView *)_webView {
    [_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    [_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
}

+ (void)openWebviewEdit:(UIWebView *)_webView {
    [_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='text';"];
    [_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='text';"];
}

@end
