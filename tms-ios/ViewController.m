//
//  ViewController.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/10.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "ViewController.h"
#import <ZipArchive.h>

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
    
//    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    [_webView loadRequest:request];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
