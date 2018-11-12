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
#import "Tools.h"
#import <MapKit/MapKit.h>
#import "ServiceTools.h"
#import "AppDelegate.h"
#import "CheckOrderPathViewController.h"
#import "IOSToVue.h"

@interface ViewController ()<UIGestureRecognizerDelegate, UIWebViewDelegate, BMKLocationServiceDelegate, ServiceToolsDelegate, CLLocationManagerDelegate> {
    
    NSURLRequest *_request;
    
    // 百度地图定位服务
    BMKLocationService *_locationService;
    
    // 记录用户最近坐标
    CLLocationCoordinate2D _location;
    
    // 第一次上传位置
    BOOL _firstLoc;
}

// 网络层
@property (strong, nonatomic) ServiceTools *service;

// 弹出3个定位受权（包括iOS11下始终允许）
@property (strong, nonatomic) CLLocationManager *reqAuth;

// 定位延迟，始终化1，允许定位后为0。 解决iOS11下无法弹出始终允许定位权限(与原生请求定位权限冲突)
@property (assign, nonatomic) unsigned PositioningDelay;

@property (assign, nonatomic) BOOL allowUpdate;

@property (strong, nonatomic) AppDelegate *app;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    if ([[_webView subviews] count] > 0) {
        // hide the shadows
        for (UIView* shadowView in [[[_webView subviews] objectAtIndex:0] subviews]) {
            [shadowView setHidden:YES];
        }
        // show the content
        [[[[[_webView subviews] objectAtIndex:0] subviews] lastObject] setHidden:NO];
    }
    _webView.backgroundColor = [UIColor whiteColor];
    for (UIView *subView in [_webView subviews]) {
        
        if ([subView isKindOfClass:[UIScrollView class]]) {
            
            for (UIView *shadowView in [subView subviews]) {
                
                if ([shadowView isKindOfClass:[UIImageView class]]) {
                    
                    shadowView.hidden = YES;
                }
            }
        }
    }
    _webView.opaque=NO;
    _webView.backgroundColor=[UIColor clearColor];
    
    UIScrollView *scroller = [_webView.subviews objectAtIndex:0];
    
    //去掉webview 上下只阴影部分
    _webView .opaque = NO;
    for (UIView *subView in [scroller subviews]) {
        
        if ([[[subView class] description] isEqualToString:@"UIImageView"]) {
            
            subView.hidden = YES;
        }
    }
    _webView.backgroundColor=[UIColor clearColor];
    
    
    // 初始化信息
    _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _allowUpdate = YES;
    
    // 长按5秒，开启webview编辑模式
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
    longPress.delegate = self;
    longPress.minimumPressDuration = 5;
    [_webView addGestureRecognizer:longPress];
    
    
    NSString *unzipPath = [Tools getUnzipPath];
    NSLog(@"unzipPath:%@", unzipPath);
    
    NSString *checkFilePath = [unzipPath  stringByAppendingPathComponent:@"dist/index.html"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:checkFilePath] && [[Tools getLastVersion] isEqualToString:[Tools getCFBundleShortVersionString]]) {
        
        NSLog(@"HTML已存在，无需解压");
    } else {
        
        NSLog(@"第一次加载，或版本有更新，解压");
        NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"dist" ofType:@"zip"];
        NSLog(@"zipPath:%@", zipPath);
        [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
    }
    [Tools setLastVersion];
    
    // 加载URL
    NSString *filePath = [NSString stringWithFormat:@"%@/dist/%@", unzipPath, @"index.html"];
    NSURL *url = [[NSURL alloc] initWithString:filePath];
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
    _request = [NSURLRequest requestWithURL:url];
    
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [[NSNotificationCenter defaultCenter] postNotificationName:kReceive_WebView_Notification object:nil userInfo:@{@"webView":_webView}];
    
    // 禁用弹簧效果
    for (id subview in _webView.subviews){
        if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
            ((UIScrollView *)subview).bounces = NO;
        }
    }
    
    
    // 取消右侧，下侧滚动条，去处上下滚动边界的黑色背景
    for (UIView *_aView in [_webView subviews]) {
        if ([_aView isKindOfClass:[UIScrollView class]]) {
            [(UIScrollView *)_aView setShowsVerticalScrollIndicator:NO];
            //右侧的滚动条
            [(UIScrollView *)_aView setShowsHorizontalScrollIndicator:NO];
            //下侧的滚动条
            for (UIView *_inScrollview in _aView.subviews) {
                if ([_inScrollview isKindOfClass:[UIImageView class]]) {
                    _inScrollview.hidden = YES;  //上下滚动出边界时的黑色的图片
                }
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [Tools closeWebviewEdit:_webView];
}


// webViewDidFinishLoad方法晚于vue的mounted函数 0.3秒左右，不采用
- (void)webViewDidStartLoad:(UIWebView *)webView{
    
    NSLog(@"------webViewDidStartLoad");
    
    // iOS监听vue的函数
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"CallAndroidOrIOS"] = ^() {
        NSString * first = @"";
        NSString * second = @"";
        NSString * third = @"";
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            first = jsVal.toString;
            break;
        }
        @try {
            JSValue *jsVal = args[1];
            second = jsVal.toString;
        } @catch (NSException *exception) { }
        @try {
            JSValue *jsVal = args[2];
            third = jsVal.toString;
        } @catch (NSException *exception) { }
        
        if([first isEqualToString:@"微信登录"]) {
            
            SendAuthReq* req = [[SendAuthReq alloc] init];
            req.scope = @"snsapi_userinfo";
            req.state = @"wechat_sdk_tms";
            dispatch_async(dispatch_get_main_queue(), ^{
                [WXApi sendReq:req];
            });
        }
        // 第一次加载登录页，不执行此函数，所以还写了一个定时器
        else if([first isEqualToString:@"登录页面已加载"]) {
            
            // 销毁定时器
            [_localTimer invalidate];
            
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]] || [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"Whatapp://"]] || [WXApi isWXAppInstalled]) {
                
                // 微信
                NSLog(@"YESWX");
            }else {
                
                // 移除微信按钮
                NSString *jsStr = [NSString stringWithFormat:@"WXInstall_Check_Ajax('%@')", @"NO"];
                NSLog(@"%@",jsStr);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_webView stringByEvaluatingJavaScriptFromString:jsStr];
                });
            }
            
            NSString *jsStrVersion = [NSString stringWithFormat:@"VersionShow('版本:%@')", [Tools getCFBundleShortVersionString]];
            NSLog(@"%@",jsStrVersion);
            dispatch_async(dispatch_get_main_queue(), ^{
                [_webView stringByEvaluatingJavaScriptFromString:jsStrVersion];
            });
            
            [IOSToVue TellVueDevice:_webView andDevice:@"iOS"];
        }
        // 导航
        else if([first isEqualToString:@"导航"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self doNavigationWithEndLocation:second];
            });
        }
        // 查看路线
        else if([first isEqualToString:@"查看路线"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self showLocLine:second];
            });
        }
        // 服务器地址
        else if([first isEqualToString:@"服务器地址"]) {
            
            [Tools setServerAddress:second];
        }
        // 记住帐号密码，开始定位
        else if([first isEqualToString:@"记住帐号密码"]) {
            
            // 启用定时器
            [self startUpdataLocationTimer];
            
            if([Tools isLocationServiceOpen]) {
                
                _PositioningDelay = 0;
            } else {
                _PositioningDelay = 1;
            }
            
            // 判断定位权限  延迟检查，因为用户首次选择需要时间
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                sleep(7);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if([Tools isLocationServiceOpen]) {
                        NSLog(@"应用拥有定位权限");
                    } else {
                        [Tools skipLocationSettings];
                    }
                });
            });
            
            // 解决iOS11下无法弹出始终允许定位权限(与原生请求定位权限冲突)
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                sleep(_PositioningDelay);
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _app.cellphone = second;
                    
                    _locationService = [[BMKLocationService alloc] init];
                    _locationService.delegate = self;
                    //启动LocationService
                    [_locationService startUserLocationService];
                    //设置定位精度
                    _locationService.desiredAccuracy = kCLLocationAccuracyHundredMeters;
                    //指定最小距离更新(米)，默认：kCLDistanceFilterNone
                    _locationService.distanceFilter = 0;
                    if(SystemVersion > 9.0) {
                        _locationService.allowsBackgroundLocationUpdates = YES;
                    }
                    _locationService.pausesLocationUpdatesAutomatically = NO;
                });
            });
            if(!_service) {
                _service = [[ServiceTools alloc] init];
            }
            _service.delegate = self;
        }
        NSLog(@"js传ios：%@   %@   %@",first, second, third);
    };
}


//导航只需要目的地经纬度，endLocation为纬度、经度的数组
-(void)doNavigationWithEndLocation:(NSString *)address {
    
    NSMutableArray *maps = [NSMutableArray array];
    
    //苹果原生地图-苹果原生地图方法和其他不一样
    NSMutableDictionary *iosMapDic = [NSMutableDictionary dictionary];
    iosMapDic[@"title"] = @"苹果地图";
    [maps addObject:iosMapDic];
    
    //高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        NSMutableDictionary *gaodeMapDic = [NSMutableDictionary dictionary];
        gaodeMapDic[@"title"] = @"高德地图";
        NSString *urlString = [NSString stringWithFormat:@"iosamap://path?sourceApplication=创云司机宝&sid=BGVIS1&slat=&slon=&sname=&did=BGVIS2&dname=%@&dev=0&t=0", address];
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        gaodeMapDic[@"url"] = urlString;
        [maps addObject:gaodeMapDic];
    }
    
    //百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
        baiduMapDic[@"title"] = @"百度地图";
        NSString *urlString = [NSString stringWithFormat:@"baidumap://map/direction?destination=%@&mode=driving&coord_type=gcj02", address];
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        baiduMapDic[@"url"] = urlString;
        [maps addObject:baiduMapDic];
    }
    
    //谷歌地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        NSMutableDictionary *googleMapDic = [NSMutableDictionary dictionary];
        googleMapDic[@"title"] = @"谷歌地图";
        NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%@&directionsmode=driving",@"导航测试",@"nav123456", address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        googleMapDic[@"url"] = urlString;
        [maps addObject:googleMapDic];
    }
    
    //选择
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"选择地图" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil])];
    
    NSInteger index = maps.count;
    
    for (int i = 0; i < index; i++) {
        
        NSString * title = maps[i][@"title"];
        
        //苹果原生地图方法
        if (i == 0) {
            
            UIAlertAction * action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                // 起点
                MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
                
                // 终点
                CLGeocoder *geo = [[CLGeocoder alloc] init];
                [geo geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                    
                    CLPlacemark *endMark=placemarks.firstObject;
                    MKPlacemark *mkEndMark=[[MKPlacemark alloc]initWithPlacemark:endMark];
                    MKMapItem *endItem=[[MKMapItem alloc]initWithPlacemark:mkEndMark];
                    NSDictionary *dict=@{
                                         MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,
                                         MKLaunchOptionsMapTypeKey:@(MKMapTypeStandard),
                                         MKLaunchOptionsShowsTrafficKey:@(YES)
                                         };
                    [MKMapItem openMapsWithItems:@[currentLocation,endItem] launchOptions:dict];\
                }];
            }];
            [alert addAction:action];
            
            continue;
        }
        
        
        UIAlertAction * action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSString *urlString = maps[i][@"url"];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }];
        
        [alert addAction:action];
        
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark 长按手势事件
-(void)longPress:(UILongPressGestureRecognizer *)sender{
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        NSLog(@"打开编辑模式");
        [Tools openWebviewEdit:_webView];
        
        // 开启编辑模式后30秒将关闭
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            usleep(30 * 1000000);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSLog(@"关闭编辑模式");
                [Tools closeWebviewEdit:_webView];
            });
        });
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}


#pragma mark - 功能函数

// 查看路线
- (void)showLocLine:(NSString *)shipmentId {
    
    CheckOrderPathViewController *vc = [[CheckOrderPathViewController alloc] init];
    vc.orderIDX = shipmentId;
    [self presentViewController:vc animated:YES completion:nil];
}

// 上传位置信息
- (void)updataLocation:(NSTimer *)timer {
    
    CLLocationCoordinate2D _lo = _location;
    if(_lo.latitude != 0 & _lo.longitude != 0)  {
        
        //判断连接状态
        if([Tools isConnectionAvailable]) {
            
            [_service reverseGeo:_app.cellphone andLon:_location.longitude andLat:_location.latitude andWebView:_webView];
        }
    }
}

// 开启间隔时间上传位置点计时器
- (void)startUpdataLocationTimer {
    if(_localTimer != nil) {
        [_localTimer invalidate];
        NSLog(@"关闭定时上传位置点信息计时器");
    }
    _localTimer = [NSTimer scheduledTimerWithTimeInterval:10 * 60 target:self selector:@selector(updataLocation:) userInfo:nil repeats:YES];
    NSLog(@"开启定时上传位置点信息计时器");
    _firstLoc = YES;
}

#pragma mark - 百度地图
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation {
    
    _location = userLocation.location.coordinate;
    NSLog(@"位置：%f   %f", _location.longitude, _location.latitude);
    
    if(_firstLoc) {
        
        [_service reverseGeo:_app.cellphone andLon:_location.longitude andLat:_location.latitude andWebView:_webView];
        _firstLoc = NO;
    }
}

@end
