//
//  Tools.h
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <UIKit/UIKit.h>
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

@end
