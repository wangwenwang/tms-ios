//
//  ServiceTools.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "ServiceTools.h"
#import <AFNetworking.h>
#import "Tools.h"

@implementation ServiceTools

- (void)queryAppVersion {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        while (1) {
            
            if([Tools getServerAddress]) {
                
                NSString *url = [NSString stringWithFormat:@"%@%@", [Tools getServerAddress], @"queryAppVersion.do"];
                AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
                NSString *params = @"{\"tenantCode\":\"KDY\"}";
                NSDictionary *parameters = @{@"params" : params};
                NSLog(@"zip检测参数：%@", parameters);
                
                [manager POST:url parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
                    nil;
                } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    
                    NSLog(@"请求成功---%@", responseObject);
                    int status = [responseObject[@"status"] intValue];
                    NSString *Msg = responseObject[@"Msg"];
                    if(status == 1) {
                        
                        NSDictionary *dict = responseObject[@"data"];
                        NSString *server_zipVersion = dict[@"zipVersionNo"];
                        NSString *currZipVersion = [Tools getZipVersion];
                        int c = [Tools compareVersion:server_zipVersion andLocati:currZipVersion];
                        if(c == 1) {
                            
                            NSString *server_zipDownloadUrl = dict[@"zipDownloadUrl"];
                            NSLog(@"更新zip...");
                            
                            if([_delegate respondsToSelector:@selector(downloadStart)]) {
                                [_delegate downloadStart];
                            }
                            [self downZip:server_zipDownloadUrl andVersion:server_zipVersion];
                        }
                    }else {
                        if([_delegate respondsToSelector:@selector(failureOfLogin:)]) {
                            [_delegate failureOfLogin:Msg];
                        }
                    }
                    
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"请求失败---%@", error);
                    if([_delegate respondsToSelector:@selector(failureOfLogin:)]) {
                        
                        [_delegate failureOfLogin:@"请求失败"];
                    }
                }];
                break;
            }else {
                
                NSLog(@"服务器地址为空，延迟1秒访问zip版本接口");
                sleep(1);
            }
        }
    });
}

- (void)downZip:(NSString *)urlStr andVersion:(NSString *)version {
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        if([_delegate respondsToSelector:@selector(downloadProgress:)]) {
            
            [_delegate downloadProgress:downloadProgress.fractionCompleted];
        }
    }  destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        NSLog(@"File downloaded to: %@", filePath);
        if([_delegate respondsToSelector:@selector(downloadCompletion:andFilePath:)]) {
            
            [_delegate downloadCompletion:version andFilePath:filePath.path];
        }
    }];
    [downloadTask resume];
}

@end
