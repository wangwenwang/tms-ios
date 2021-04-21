//
//  IOSToVue.h
//  tms-ios
//
//  Created by wenwang wang on 2018/11/9.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOSToVue : NSObject

/// 告诉Vue设备标识（iOS）
+ (void)TellVueDevice:(nullable WKWebView *)webView andDevice:(nullable NSString *)dev;


/// 让Vue隐藏【导航】按钮，苹果审核不允许导航跳转至其它APP（若当前地址为审核小组的地址将按钮隐藏）
+ (void)TellVueHiddenNav:(nullable WKWebView *)webView;


/// 告诉Vue微信登录成功，并传递司机的个人信息给Vue
+ (void)TellVueWXBind_YES_Ajax:(nullable WKWebView *)webView andParamsEncoding:(nullable NSString *)paramsEncoding;


/// 告诉Vue微信登录失败，传递openid让其关联（通过openid关联【配货易司机S】帐号）
+ (void)TellVueWXBind_NO_Ajax:(nullable WKWebView *)webView andOpenid:(nullable NSString *)openid;


/// 告诉Vue设备未安装微信，让其移除微信登录按钮（审核小组不允许未安装微信的手机中出现【微信登录】按钮）
+ (void)TellVueWXInstall_Check_Ajax:(nullable WKWebView *)webView andIsInstall:(nullable NSString *)isInstall;


/// 告诉Vue版本号
+ (void)TellVueVersionShow:(nullable WKWebView *)webView andVersion:(nullable NSString *)version;


/// 告诉Vue当前地址
+ (void)TellVueCurrAddress:(nullable WKWebView *)webView andAddress:(nullable NSString *)address andLon:(float)lon andLat:(float)lat;


/// 告诉Vue是否播报声音
+ (void)TellVueVoiceStatus:(nullable WKWebView *)webView andStatus:(nullable NSString *)status;

@end
