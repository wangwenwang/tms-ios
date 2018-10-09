//
//  Tools.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "Tools.h"
#import <MBProgressHUD.h>

#define LAT_OFFSET_0(x,y) -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x))
#define LAT_OFFSET_1 (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0
#define LAT_OFFSET_2 (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0
#define LAT_OFFSET_3 (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0

#define LON_OFFSET_0(x,y) 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x))
#define LON_OFFSET_1 (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0
#define LON_OFFSET_2 (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0
#define LON_OFFSET_3 (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0

#define RANGE_LON_MAX 137.8347
#define RANGE_LON_MIN 72.004
#define RANGE_LAT_MAX 55.8271
#define RANGE_LAT_MIN 0.8293

#define jzA 6378245.0
#define jzEE 0.00669342162296594323

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

+ (BOOL)isLocationServiceOpen {
    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)isConnectionAvailable {
    BOOL isExistenceNetwork = YES;
    Reachability *reach = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    
    switch ([reach currentReachabilityStatus]) {
        case NotReachable:
            isExistenceNetwork = NO;
            //NSLog(@"notReachable");
            break;
        case ReachableViaWiFi:
            isExistenceNetwork = YES;
            //NSLog(@"WIFI");
            break;
        case ReachableViaWWAN:
            isExistenceNetwork = YES;
            //NSLog(@"3G");
            break;
    }
    return isExistenceNetwork;
}

+ (void)showAlert:(UIView *)view andTitle:(NSString *)title {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = title;
    hud.margin = 15.0f;
    hud.removeFromSuperViewOnHide = YES;
    hud.userInteractionEnabled = NO;
    [hud hideAnimated:YES afterDelay:1.5];
}

+ (CLLocationCoordinate2D)wgs84ToGcj02:(CLLocationCoordinate2D)location {
    return [self gcj02Encrypt:location.latitude bdLon:location.longitude];
}

+ (CLLocationCoordinate2D)gcj02Encrypt:(double)ggLat bdLon:(double)ggLon {
    CLLocationCoordinate2D resPoint;
    double mgLat;
    double mgLon;
    if ([self outOfChina:ggLat bdLon:ggLon]) {
        resPoint.latitude = ggLat;
        resPoint.longitude = ggLon;
        return resPoint;
    }
    double dLat = [self transformLat:(ggLon - 105.0)bdLon:(ggLat - 35.0)];
    double dLon = [self transformLon:(ggLon - 105.0) bdLon:(ggLat - 35.0)];
    double radLat = ggLat / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1 - jzEE * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((jzA * (1 - jzEE)) / (magic * sqrtMagic) * M_PI);
    dLon = (dLon * 180.0) / (jzA / sqrtMagic * cos(radLat) * M_PI);
    mgLat = ggLat + dLat;
    mgLon = ggLon + dLon;
    
    resPoint.latitude = mgLat;
    resPoint.longitude = mgLon;
    return resPoint;
}

+ (BOOL)outOfChina:(double)lat bdLon:(double)lon {
    if (lon < RANGE_LON_MIN || lon > RANGE_LON_MAX)
        return true;
    if (lat < RANGE_LAT_MIN || lat > RANGE_LAT_MAX)
        return true;
    return false;
}

+ (double)transformLat:(double)x bdLon:(double)y {
    double ret = LAT_OFFSET_0(x, y);
    ret += LAT_OFFSET_1;
    ret += LAT_OFFSET_2;
    ret += LAT_OFFSET_3;
    return ret;
}

+ (double)transformLon:(double)x bdLon:(double)y {
    double ret = LON_OFFSET_0(x, y);
    ret += LON_OFFSET_1;
    ret += LON_OFFSET_2;
    ret += LON_OFFSET_3;
    return ret;
}

@end
