//
//  Tools.h
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import <Foundation/Foundation.h>

@interface Tools : NSObject

/// 获取zip版本号
+ (NSString *)getZipVersion;


/// 设置zip版本号
+ (void)setZipVersion:(NSString *)version;


/// 获取服务器地址
+ (NSString *)getServerAddress;


/// 设置服务器地址
+ (void)setServerAddress:(NSString *)baseUrl;


/// 版本号比较，1为服务器>本地，0为服务器=本地，-1为服务器<本地，-2为版本号不合法
+ (int)compareVersion:(NSString *)server andLocati:(NSString *)locati;


/// 获取解压zip路径
+ (NSString *)getUnzipPath;


/// 关闭Webview编辑功能
+ (void)closeWebviewEdit:(UIWebView *)_webView;


/// 打开Webview编辑功能
+ (void)openWebviewEdit:(UIWebView *)_webView;


/// 判断是否允许定位
+ (BOOL)isLocationServiceOpen;


/// 判断网络状态
+ (BOOL)isConnectionAvailable;


/// 提示  参数:View    NSString
+ (void)showAlert:(UIView *)view andTitle:(NSString *)title;


/**
 提示带时间参数
 @param view  父窗口
 @param title 标题
 @param time  停留时间
 */
+ (void)showAlert:(nullable UIView *)view andTitle:(nullable NSString *)title andTime:(NSTimeInterval)time;


/// 设置上一次启动的版本号
+ (void)setLastVersion;


/// 获取上一次启动的版本号
+ (nullable NSString *)getLastVersion;


/// 获取当前版本号
+ (nullable NSString *)getCFBundleShortVersionString;


/// 检测位置权限
+ (void)skipLocationSettings;

@end
