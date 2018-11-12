//
//  IOSToVue.h
//  tms-ios
//
//  Created by wenwang wang on 2018/11/9.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOSToVue : NSObject

+ (void)TellVueDevice:(nullable UIWebView *)webView andDevice:(nullable NSString *)dev;

+ (void)TellVueCurrAddress:(nullable UIWebView *)webView andAddress:(nullable NSString *)address;

@end
