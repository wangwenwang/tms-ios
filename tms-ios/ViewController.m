//
//  ViewController.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/10.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "ViewController.h"
#import <ZipArchive.h>
#import <WXApi.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface ViewController () {
    
    NSURLRequest *_request;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"dist" ofType:@"zip"];
    NSLog(@"zipPath:%@", zipPath);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentpath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *unzipPath = [documentpath stringByAppendingPathComponent:@"/test"];
    NSLog(@"unzipPath:%@", unzipPath);
    
    // Unzip
    [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
    
    // 加载URL
    NSString *filePath = [NSString stringWithFormat:@"%@/dist/%@", unzipPath, @"index.html"];
    NSURL *url = [[NSURL alloc] initWithString:filePath];
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
    _request = [NSURLRequest requestWithURL:url];
    
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [[NSNotificationCenter defaultCenter] postNotificationName:kReceive_WebView_Notification object:nil userInfo:@{@"webView":_webView}];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]] || [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"Whatapp://"]] || [WXApi isWXAppInstalled]) {
        
        //微信
        NSLog(@"YES");
    }else {
        
        // 移除微信按钮
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            for (int i = 0; i < 20; i++) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSString *jsStr = [NSString stringWithFormat:@"WXInstall_Check_Ajax('%@')", @"NO"];
                    NSLog(@"%@",jsStr);
                    [_webView stringByEvaluatingJavaScriptFromString:jsStr];
                });
                usleep(100000);
            }
        });
    }
    
    // 显示版本号
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        for (int i = 0; i < 20; i++) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
                NSString *jsStrVersion = [NSString stringWithFormat:@"VersionShow('版本:%@')", app_Version];
                NSLog(@"%@",jsStrVersion);
                [_webView stringByEvaluatingJavaScriptFromString:jsStrVersion];
            });
            usleep(100000);
        }
    });
    
    
    NSString *jsStr = [NSString stringWithFormat:@"QRScanAjax('%@', '%@', '%@', '%@',)" ,@"1" ,@"2" ,@"3" ,@"4"];
    NSLog(@"%@",jsStr);
    [_webView stringByEvaluatingJavaScriptFromString:jsStr];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    // iOS监听vue的函数
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"CallAndroidOrIOS"] = ^() {
        NSString * qrscanDes = @"";
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            qrscanDes = jsVal.toString;
            break;
        }
        
        if([qrscanDes isEqualToString:@"微信登录"]) {
            
            SendAuthReq* req = [[SendAuthReq alloc] init];
            req.scope = @"snsapi_userinfo";
            req.state = @"wechat_sdk_tms";
            dispatch_async(dispatch_get_main_queue(), ^{
                [WXApi sendReq:req];
            });
        }
        // 第一次加载登录页，不执行此函数，所以还写了一个定时器
        else if([qrscanDes isEqualToString:@"登录页面已加载"]) {
            
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]] || [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"Whatapp://"]] || [WXApi isWXAppInstalled]) {
                
                //微信
                NSLog(@"YESWX");
            }else {
                
                // 移除微信按钮
                NSString *jsStr = [NSString stringWithFormat:@"WXInstall_Check_Ajax('%@')", @"NO"];
                NSLog(@"%@",jsStr);
                [_webView stringByEvaluatingJavaScriptFromString:jsStr];
            }
            
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
            NSString *jsStrVersion = [NSString stringWithFormat:@"VersionShow('版本:%@')", app_Version];
            NSLog(@"%@",jsStrVersion);
            [_webView stringByEvaluatingJavaScriptFromString:jsStrVersion];
        }
        NSLog(@"%@",qrscanDes);
    };
}


@end
