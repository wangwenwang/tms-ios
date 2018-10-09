//
//  ViewController.h
//  tms-ios
//
//  Created by wenwang wang on 2018/9/10.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *webView;

// 计时器，固定间隔时间上传位置信息
@property (strong, nonatomic) NSTimer *localTimer;

@end

