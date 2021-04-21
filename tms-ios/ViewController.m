//
//  ViewController.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/10.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "ViewController.h"
#import "XHVersion.h"

#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<UIGestureRecognizerDelegate, BMKLocationServiceDelegate, ServiceToolsDelegate, CLLocationManagerDelegate, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate, WKUIDelegate, WKScriptMessageHandler> {
    
    // 百度地图定位服务
    BMKLocationService *_locationService;
    
    // 记录用户最近坐标
    CLLocationCoordinate2D _location;
    
    // 第一次上传位置
    BOOL _firstLoc;
}

// 计时器，固定间隔时间上传位置信息
@property (strong, nonatomic) NSTimer *localTimer;

// 网络层
@property (strong, nonatomic) ServiceTools *service;

// 弹出3个定位受权（包括iOS11下始终允许）
@property (strong, nonatomic) CLLocationManager *reqAuth;

// 定位延迟，始终化1，允许定位后为0。 解决iOS11下无法弹出始终允许定位权限(与原生请求定位权限冲突)
@property (assign, nonatomic) unsigned PositioningDelay;

@property (assign, nonatomic) BOOL allowUpdate;

@property (strong, nonatomic) AppDelegate *app;
 
/** 播报的内容 */
@property (nonatomic, readwrite , strong) AVSpeechSynthesizer *synth;
/** 负责播放 */
@property (nonatomic, readwrite , strong) AVSpeechUtterance *utterance;
/** 静音播放 */
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

@implementation ViewController

- (void)playOnOtherMusic:(NSString *)text{
    
    // 设置音频类别
    NSError *setCategoryError = nil;
    BOOL isSuccess = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers error:&setCategoryError];
    if (isSuccess) {
        NSLog(@"设置音频类别成功");
    }else{
        NSLog(@"不能设置音频类别");
        NSLog(@"%@", setCategoryError.localizedDescription);
    }
    
    __weak typeof(self) weakSelf = self;
    //创建播放器并播放
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *filePath = [[NSBundle mainBundle]pathForResource:@"wrong01_2" ofType:@"mp3"];
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        NSError *audioPlayerError = nil;
        weakSelf.audioPlayer = [[AVAudioPlayer alloc]initWithData:fileData error:&audioPlayerError];
        if (weakSelf.audioPlayer != nil) {
            weakSelf.audioPlayer.delegate = self;
            if ([weakSelf.audioPlayer prepareToPlay] && [weakSelf.audioPlayer play]) {
                NSLog(@"Successfully started playing.");
            }else{
                NSLog(@"Failed to play the audio file.");
                weakSelf.audioPlayer = nil;
            }
        }else{
            NSLog(@"Could not instantiate the audio player.");
        }
    });
    self.utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    // 播报的语速
    self.utterance.rate = AVSpeechUtteranceDefaultSpeechRate;
    // 中式发音
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    self.utterance.voice = voice;
    self.synth = [[AVSpeechSynthesizer alloc] init];
    self.synth.delegate = self;
    [self.synth speakUtterance:self.utterance];
}

// 接下来,我们继续处理 AVAudioPlayerDelegate 协议方法:
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{
    
    /* The audio session has been deactivated here */
    NSLog(@"fsd");
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags{
    
    // 打断结束
    if (flags == AVAudioSessionInterruptionOptionShouldResume){
        [player play];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    
    // 播放结束
    if (flag){
        NSLog(@"Audio player stopped correctly.");
    } else {
        NSLog(@"Audio player did not stop correctly.");
    }
    if ([player isEqual:self.audioPlayer]){
        self.audioPlayer = nil;
    } else {
        /* This is not the audio player */
    }
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self playOnOtherMusic:@""];
    
    [self addWebView];
    
    UIImageView *imageV = [[UIImageView alloc] init];
    
    NSLog(@"ScreenHeight:%f", ScreenHeight);
    NSString *imageName = @"";
    
    if(ScreenHeight == 480) {
        
        // iPhone4S
        imageName = @"640 × 960";
    }else if(ScreenHeight == 568){
        
        // iPhone5S、iPhoneSE
        imageName = @"640 × 1136";
    }else if(ScreenHeight == 667){
        
        // iPhone6、iPhone6S、iPhone7、iPhone8
        imageName = @"750 × 1334";
    }else if(ScreenHeight == 736){
        
        // iPhone6P、iPhone6SP、iPhone7P、iPhone8P
        imageName = @"1242 × 2208";
    }else if(ScreenHeight == 812){
        
        // iPhoneX、iPhoneXS
        imageName = @"1125 × 2436";
    }else {
        
        // iPhoneXR、iPhoneXSMAX
        imageName = @"1125 × 2436";
        [Tools showAlert:self.view andTitle:@"未知设备" andTime:5];
    }
    
    [imageV setImage:[UIImage imageNamed:imageName]];
    [imageV setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [self.view addSubview:imageV];
    
    [UIView animateWithDuration:0.8 delay:0.8 options:0 animations:^{
        
        [imageV setAlpha:0];
    } completion:^(BOOL finished) {
        
        [imageV removeFromSuperview];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


- (void)webViewDidFinishLoad:(WKWebView *)webView {
    
    [Tools closeWebviewEdit:_webView];
}


// webViewDidFinishLoad方法晚于vue的mounted函数 0.3秒左右，不采用
- (void)webViewDidStartLoad:(WKWebView *)webView{
    
    // iOS监听vue的函数
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context[@"CallAndroidOrIOS"] = ^() {
        NSString * first = @"";
        NSString * second = @"";
        NSString * third = @"";
        NSString * fourth = @"";
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
        @try {
            JSValue *jsVal = args[3];
            fourth = jsVal.toString;
        } @catch (NSException *exception) { }
    };
}


//导航只需要目的地经纬度，endLocation为纬度、经度的数组
-(void)doNavigationWithEndLocation:(NSString *)address andLng:(NSString *)lng andLat:(NSString *)lat andName:(NSString *)name {
    
    NSMutableArray *maps = [NSMutableArray array];
    
    //苹果原生地图-苹果原生地图方法和其他不一样
    NSMutableDictionary *iosMapDic = [NSMutableDictionary dictionary];
    iosMapDic[@"title"] = @"苹果地图";
    [maps addObject:iosMapDic];
    
    //高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        NSMutableDictionary *gaodeMapDic = [NSMutableDictionary dictionary];
        gaodeMapDic[@"title"] = @"高德地图";
        NSString *urlString;
        if(lng && lat){
            urlString = [NSString stringWithFormat:@"iosamap://path?sourceApplication=配货易司机S&sid=BGVIS1&slat=&slon=&sname=&did=BGVIS2&dlat=%@&dlon=%@&dname=%@&dev=0&m=0&t=0", lat, lng, name];
        }else{
            urlString = [NSString stringWithFormat:@"iosamap://path?sourceApplication=配货易司机S&sid=BGVIS1&slat=&slon=&sname=&did=BGVIS2&dname=%@&dev=0&t=0", address];
        }
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        gaodeMapDic[@"url"] = urlString;
        [maps addObject:gaodeMapDic];
    }
    
    //百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
        baiduMapDic[@"title"] = @"百度地图";
        NSString *urlString;
        if(lng && lat){
            urlString = [NSString stringWithFormat:@"baidumap://map/direction?destination=%@,%@&mode=driving&coord_type=gcj02&src=%@", lat, lng, name];
        }else{
            urlString = [NSString stringWithFormat:@"baidumap://map/direction?destination=%@&mode=driving&coord_type=gcj02", address];
        }
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
                // 配置
                NSDictionary *dict = @{
                    MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,
                    MKLaunchOptionsMapTypeKey:@(MKMapTypeStandard),
                    MKLaunchOptionsShowsTrafficKey:@(YES)
                };
                // 终点
                if(lng && lat){
                    CLLocationCoordinate2D lng_lat = CLLocationCoordinate2DMake([lat floatValue], [lng floatValue]);
                    MKMapItem *to_lng_lat = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:lng_lat addressDictionary:nil]];
                    to_lng_lat.name = name;
                    [MKMapItem openMapsWithItems:@[currentLocation, to_lng_lat] launchOptions:dict];
                }else{
                    CLGeocoder *geo = [[CLGeocoder alloc] init];
                    [geo geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                        
                        CLPlacemark *endMark = placemarks.firstObject;
                        MKPlacemark *mkEndMark = [[MKPlacemark alloc]initWithPlacemark:endMark];
                        MKMapItem *endItem = [[MKMapItem alloc]initWithPlacemark:mkEndMark];
                        
                        [MKMapItem openMapsWithItems:@[currentLocation, endItem] launchOptions:dict];
                    }];
                }
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


#pragma mark GET方法
- (void)addWebView {
    
    if(_webView == nil) {
        
        // wk代理
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.userContentController = [[WKUserContentController alloc] init];
        [config.userContentController addScriptMessageHandler:self name:@"messageSend"];
        config.preferences = [[WKPreferences alloc] init];
        config.preferences.minimumFontSize = 0;
        config.preferences.javaScriptEnabled = YES;
        config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, kStatusHeight, ScreenWidth, ScreenHeight - kStatusHeight - SafeAreaBottomHeight) configuration:config];
        [self.view addSubview:_webView];
        
        
        // 初始化信息
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _allowUpdate = YES;
        
        // 长按5秒，开启webview编辑模式
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
        longPress.delegate = self;
        longPress.minimumPressDuration = 3;
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
        NSString *basePath = [NSString stringWithFormat:@"%@/dist/%@", unzipPath, @""];
        NSURL *baseUrl = [NSURL fileURLWithPath:basePath];
        NSURL *fileUrl = [self fileURLForBuggyWKWebView8WithFileURL:baseUrl];
        
        [_webView loadRequest:[NSURLRequest requestWithURL:fileUrl]];
        
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
                // 右侧的滚动条
                [(UIScrollView *)_aView setShowsHorizontalScrollIndicator:NO];
                // 下侧的滚动条
                for (UIView *_inScrollview in _aView.subviews) {
                    if ([_inScrollview isKindOfClass:[UIImageView class]]) {
                        _inScrollview.hidden = YES;  // 上下滚动出边界时的黑色的图片
                    }
                }
            }
        }
    }
}

#pragma mark - WKScriptMessageHandler
//当js 通过 注入的方法 @“messageSend” 时会调用代理回调。 原生收到的所有信息都通过此方法接收。
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSLog(@"原生收到了js发送过来的消息 message.body = %@",message.body);
    
    __weak __typeof(self)weakSelf = self;
    
    if([message.name isEqualToString:@"messageSend"]){
        
        // 第一次加载登录页，不执行此函数，所以还写了一个定时器
        if([message.body[@"a"] isEqualToString:@"微信登录"]){
            
            SendAuthReq* req = [[SendAuthReq alloc] init];
            req.scope = @"snsapi_userinfo";
            req.state = @"wechat_sdk_tms";
            dispatch_async(dispatch_get_main_queue(), ^{
                [WXApi sendReq:req];
            });
        }
        else if([message.body[@"a"] isEqualToString:@"登录页面已加载"]){
            
            // 销毁定时器
            [_localTimer invalidate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]] || [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"Whatapp://"]] || [WXApi isWXAppInstalled]) {
                    
                    // 微信
                    NSLog(@"设备已安装【微信】");
                }else {
                    
                    // 移除微信按钮
                    [IOSToVue TellVueWXInstall_Check_Ajax:_webView andIsInstall:@"NO"];
                }
            });
            
            // 发送APP版本号
            [IOSToVue TellVueVersionShow:_webView andVersion:[NSString stringWithFormat:@"版本:%@", [Tools getCFBundleShortVersionString]]];
            
            // 发送设备标识
            [IOSToVue TellVueDevice:_webView andDevice:@"iOS"];
            
            // 发送是否播报标识
            [IOSToVue TellVueVoiceStatus:_webView andStatus:[Tools getVoiceStatus]];
            
            // 停止定位功能、销毁定时器
            [_localTimer invalidate];
            [_locationService stopUserLocationService];
        }
        else if([message.body[@"a"] isEqualToString:@"导航"]){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *b = message.body[@"b"];
                NSString *lng = message.body[@"c_lng"];
                NSString *lat = message.body[@"d_lat"];
                NSString *name = message.body[@"e_name"];
                [self doNavigationWithEndLocation:b andLng:lng andLat:lat andName:name];
            });
        }
        else if([message.body[@"a"] isEqualToString:@"查看路线"]){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self showLocLine:message.body[@"b"] andShipmentCode:message.body[@"c"] andShipmentStatus:message.body[@"d"]];
            });
        }
        else if([message.body[@"a"] isEqualToString:@"服务器地址"]){
            
            [Tools setServerAddress:message.body[@"b"]];
        }
        // 记住帐号密码，开始定位
        else if([message.body[@"a"] isEqualToString:@"记住帐号密码"]){
            // 启用定时器
            [self startUpdataLocationTimer];
            
            if([Tools isLocationServiceOpen]) {
                
                _PositioningDelay = 0;
            } else {
                
                _PositioningDelay = 1;
            }
            
            // 判断定位权限  延迟检查，因为用户首次选择需要时间
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                NSString *enter = [Tools getEnterTheHomePage];
                if([enter isEqualToString:@"YES"]) {
                    sleep(3);
                }else {
                    sleep(10);
                }
                [Tools setEnterTheHomePage:@"YES"];
                
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
                    
                    _app.cellphone = message.body[@"b"];
                    
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
            
            // 检查更新
            [XHVersion checkNewVersion];
        }
        // 获取当前位置页面已加载，预留接口，防止js获取当前位置出问题
        else if([message.body[@"a"] isEqualToString:@"获取当前位置页面已加载"]){
            
            [_service reverseGeo:_app.cellphone andLon:_location.longitude andLat:_location.latitude andWebView:_webView andTimingTrackingOrTellVue:GeoOfTellVue];
        }
        // 声音播报状态
        else if([message.body[@"a"] isEqualToString:@"声音播报状态"]){
            
            NSString *f = message.body[@"b"];
            [Tools setVoiceStatus:message.body[@"b"]];
        }
        else if([message.body[@"a"] isEqualToString:@"检查版本更新"]){
            
            // 检查更新
            [XHVersion checkNewVersion];
            
            // 2.如果你需要自定义提示框,请使用下面方法
            [XHVersion checkNewVersionAndCustomAlert:^(XHAppInfo *appInfo) {
                
                NSLog(@"新版本信息:\n 版本号 = %@ \n 更新时间 = %@\n 更新日志 = %@ \n 在AppStore中链接 = %@\n AppId = %@ \n bundleId = %@" ,appInfo.version,appInfo.currentVersionReleaseDate,appInfo.releaseNotes,appInfo.trackViewUrl,appInfo.trackId,appInfo.bundleId);
            } andNoNewVersionBlock:^(XHAppInfo *appInfo) {
                
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"已经是最新版本" message:@"" delegate:self cancelButtonTitle:@"确定", nil];
                [alertView show];
#endif
                
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已经是最新版本" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                }]];
                [self presentViewController:alert animated:YES completion:nil];
#endif
            }];
        }
    }
}

#pragma mark - WKWebViewDelegate
- (NSURL *)fileURLForBuggyWKWebView8WithFileURL: (NSURL *)fileURL {
    NSError *error = nil;
    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
        return nil;
    }
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSURL *temDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"www"];
    [fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error];
     NSURL *htmlDestURL = [temDirURL URLByAppendingPathComponent:fileURL.lastPathComponent];
    [fileManager removeItemAtURL:htmlDestURL error:&error];
    [fileManager copyItemAtURL:fileURL toURL:htmlDestURL error:&error];
    NSURL *finalHtmlDestUrl = [htmlDestURL URLByAppendingPathComponent:@"index.html"];
    return finalHtmlDestUrl;
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
- (void)showLocLine:(NSString *)shipmentId andShipmentCode:(NSString *)shipmentCode andShipmentStatus:(NSString *)shipmentStatus {
    
    CheckOrderPathViewController *vc = [[CheckOrderPathViewController alloc] init];
    vc.orderIDX = shipmentId;
    vc.shipmentCode = shipmentCode;
    vc.shipmentStatus = shipmentStatus;
    [self presentViewController:vc animated:YES completion:nil];
}

// 上传位置信息
- (void)updataLocation:(NSTimer *)timer {
    
    CLLocationCoordinate2D _lo = _location;
    if(_lo.latitude != 0 & _lo.longitude != 0)  {
        
        //判断连接状态
        if([Tools isConnectionAvailable]) {
            
            [_service reverseGeo:_app.cellphone andLon:_location.longitude andLat:_location.latitude andWebView:_webView andTimingTrackingOrTellVue:GeoOfTimingTracking];
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
    _app.currLatlng = userLocation.location.coordinate;
    NSLog(@"位置：%f   %f  ", _location.longitude, _location.latitude);
    
    if(_firstLoc) {
        
        [_service reverseGeo:_app.cellphone andLon:_location.longitude andLat:_location.latitude andWebView:_webView andTimingTrackingOrTellVue:GeoOfTimingTracking];
        _firstLoc = NO;
    }
}

@end
