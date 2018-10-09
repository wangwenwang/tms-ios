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


/// 查询版本号
- (void)queryAppVersion;


/// 反地理编码，完成后上传位置点
- (void)reverseGeo:(NSString *)cellphone andLon:(double)lon andLat:(double)lat;

@end
