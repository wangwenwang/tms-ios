//
//  IOSToVue.m
//  tms-ios
//
//  Created by wenwang wang on 2018/11/9.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "IOSToVue.h"

@implementation IOSToVue

+ (void)TellVueCurrAddress:(nullable UIWebView *)webView andAddress:(nullable NSString *)address {
    
    NSString *jsStr = [NSString stringWithFormat:@"HiddenNav('%@')",address];
    NSLog(@"%@",jsStr);
    [webView stringByEvaluatingJavaScriptFromString:jsStr];
}

+ (void)TellVueDevice:(nullable UIWebView *)webView andDevice:(nullable NSString *)dev {
    
    NSString *jsStr = [NSString stringWithFormat:@"Device_Ajax('%@')",dev];
    NSLog(@"%@",jsStr);
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView stringByEvaluatingJavaScriptFromString:jsStr];
    });
}

@end
