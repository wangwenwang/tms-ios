//
//  ServiceTools.h
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServiceToolsDelegate <NSObject>

@optional
- (void)successOfQueryAppVersion:(NSString *)zipVersionNo andZipDownloadUrl:(NSString *)zipDownloadUrl;

@optional
- (void)failureOfLogin:(NSString *)msg;

@optional
- (void)downloadStart;

@optional
- (void)downloadProgress:(double)progress;

@optional
- (void)downloadCompletion:(NSString *)version andFilePath:(NSString *)filePath;


@end

@interface ServiceTools : NSObject

@property (weak, nonatomic)id <ServiceToolsDelegate> delegate;

- (void)queryAppVersion;

@end
