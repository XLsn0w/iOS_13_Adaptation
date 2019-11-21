//
//  Adapter.m
//  ChineseMedicine
//
//  Created by mac on 2019/11/18.
//  Copyright © 2019 fbw. All rights reserved.
/*
 暗黑模式 Dark Mode 适配（没有适配暗黑模式之前，先禁用，Info.plist文件中UIUserInterfaceStyle设置为light）
 1.UIColor
 UIColor在iOS13系统上拥有了动态属性，iOS13之前UIColor只能表示一种颜色，iOS13以后能够表示两种模式下的不同颜色（例如：普通模式Light-白底黑字，暗黑模式Dark-黑底白字）
 iOS13系统提供了一些动态颜色，也可以自定义动态颜色，下面我们一起看看使用事例，图片为效果图：

 a.系统提供的动态颜色UIColor
 [self.view setBackgroundColor:[UIColor systemBackgroundColor]]; // 13系统颜色方法，还有更多
 [self.titleLabel setTextColor:[UIColor labelColor]]; // 13系统颜色方法
 [self.detailLabel setTextColor:[UIColor placeholderTextColor]]; // 13系统颜色方法

 b.自定义动态颜色UIColor
 + (UIColor *)colorWithDynamicProvider:(UIColor * (^)(UITraitCollection *))dynamicProvider API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 - (UIColor *)initWithDynamicProvider:(UIColor * (^)(UITraitCollection *))dynamicProvider API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 备注：这两个发发要求传入一个block进去，当系统切换LightMode和DarkMode时会触发此回调，并且这个Block会返回一个UITraitCollection类，我们需要使用其属性userInterfaceStyle来判断是LightMode还是DarkMode
 UIColor *dyColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trainCollection) {
         if ([trainCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
             return [UIColor redColor];
         }
         else {
             return [UIColor greenColor];
         }
     }];
  [self.bgView setBackgroundColor:dyColor];

 c.iOS13中的CGColor
 依然只能表示单一的颜色，但可以利用下面这个方法来判断的:
 获取当前模式（Light or Dark）：UITraitCollection.currentTraitCollection.userInterfaceStyle
 还有就是对于CALayer等对象如何适配暗黑模式呢？
 方法一：resolvedColor
 通过当前traitCollection得到对应UIColor（比如控制器重写坚挺暗黑模式改变方法），然后将UIColor转换为CGColor
 - (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traitCollection;
 - (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
     [super traitCollectionDidChange:previousTraitCollection];
     UIColor *dyColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trainCollection) {
         if ([trainCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
             return [UIColor redColor];
         }
         else {
             return [UIColor greenColor];
         }
     }];
     UIColor *resolvedColor = [dyColor resolvedColorWithTraitCollection:previousTraitCollection];
     layer.backgroundColor = resolvedColor.CGColor;
 }
 方法二：performAsCurrent
 使用当前trainCollection调用这个方法- (void)performAsCurrentTraitCollection:(void (^)(void))actions;
 - (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
     [super traitCollectionDidChange:previousTraitCollection];
     UIColor *dyColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trainCollection) {
         if ([trainCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
             return [UIColor redColor];
         }
         else {
             return [UIColor greenColor];
         }
     }];
     [self.traitCollection performAsCurrentTraitCollection:^{
         layer.backgroundColor = dyColor.CGColor;
     }];
 }
 方法三：最简单的方法
 直接设置为一个动态UIColor的CGColor即可
 - (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
     [super traitCollectionDidChange:previousTraitCollection];
     UIColor *dyColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trainCollection) {
         if ([trainCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
             return [UIColor redColor];
         }
         else {
             return [UIColor greenColor];
         }
     }];
         layer.backgroundColor = dyColor.CGColor;
 }
 注意：设置layer颜色都是在traitCollectionDidChange中，意味着如果没有发生模式切换，layer将会没有颜色，需要设置一个基本颜色

 d.控制器监听暗黑模式：（有时需求会用到，所以在ViewController中重写下面的方法就好了）
 - (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection; // 注意:参数为变化前的traitCollection
 - (BOOL)hasDifferentColorAppearanceComparedToTraitCollection:(UITraitCollection *)traitCollection; // 判断两个UITraitCollection对象是否不同
 - (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
     [super traitCollectionDidChange:previousTraitCollection];
     // trait发生了改变
     if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
     // 执行操作
     }
 }

 e.模式切换时打印log
 很方便的一种设置方式，操作步骤：
 Xcode菜单栏-Product-Scheme-Edit Scheme - Run - Arguments Passed On Launch - 添加命令-UITraitCollectionChangeLoggingEnabled YES
 ![模式切换时打印log.png](https://upload-images.jianshu.io/upload_images/9062174-a492101c22f6409b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

 f.强行设置APP模式
 控制器页面直接设置 设置为Dark Mode即可，在View或者ViewController中可以设置，需要注意的是，当我们强行设置之后，这个ViewController下的View都是设置的模式，由这个控制器模态推出的控制器依然跟随系统模式，如果想一键设置APP下所有的ViewController都是Dark Mode，直接window执行overrideUserInterfaceStyle，window.rootViewController强行设置Dark Mode后模态推出的控制器依然跟随系统模式
 [self setOverrideUserInterfaceStyle:UIUserInterfaceStyleDark];

 g.NSAttributedString暗黑模式优化
 NSDictionary *dic = @{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor labelColor]};
 NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"富文本文案" attributes:dic];// 添加一个NSForegroundColorAttributeName属性

 2.图片-暗黑模式（在iOS13暗黑模式下自由切换图片）
 开发时需要放入两套2x3x图了---Any Apperarance、Dark Apperarance
 详细步骤：a.打开Assets.xcassets
         b.新建一个Image Set
         c.打开右侧工具栏，点击最后一栏，找到Appearances，选择Any,Dark
         d.将两种模式下的图片拖放进去就可以了

 以上就是颜色和图片的Dark Mode适配
 */

#import "Adapter.h"

@implementation Adapter

@end

/*
 2.私有方法 KVC 不允许使用
 在 iOS 13 中不再允许使用 valueForKey、setValue:forKey: 等方法获取或设置私有属性，虽然编译可以通过，但是在运行时会直接崩溃

 // 使用的私有方法
 [textField setValue:UIColor_d2 forKeyPath:@"_placeholderLabel.textColor"];
 textField.placeholder = placeholderStr;
 崩溃信息：

 // 崩溃提示信息
 *** Terminating app due to uncaught exception 'NSGenericException', reason: 'Access to UITextField's _placeholderLabel ivar is prohibited. This is an application bug'

 解决方案:

 NSMutableAttributedString *placeholderString = [[NSMutableAttributedString alloc] initWithString:placeholderStr
                                                                                       attributes:@{NSForegroundColorAttributeName:UIColor_d2}];
 textField.attributedPlaceholder = placeholderString;

 
 3.推送的 NSData* deviceToken 获取到的格式发生变化
 原本可以直接将 NSData 类型的 deviceToken 转换成 NSString 字符串，然后替换掉多余的符号即可：

 - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
     NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
     token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
     NSLog(@"deviceToken:%@", token);
 }
 在 iOS 13 中，这种方法已经失效，NSData 类型的 deviceToken 转换成的字符串变成了：

 {length=32,bytes=0xd02daa63aade35488d1e24206f44037d...fd6b2fac80bddd2d}

 需要进行一次数据格式处理，参考友盟的做法，可以适配新旧系统，获取方式如下：

 - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
     if (![deviceToken isKindOfClass:[NSData class]]) return;
     const unsigned *tokenBytes = [deviceToken bytes];
     NSString *token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                           ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                           ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                           ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
     NSLog(@"deviceToken:%@", token);
 }
 这样就获取到正确的 deviceToken 字符串

 d02daa63aade35488d1e24206f44037dce9ece7f85adf6acfd6b2fac80bddd2d

 - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
     if (@available(iOS 13.0, *)) {
         if (![deviceToken isKindOfClass:[NSData class]]) return;
         const unsigned *tokenBytes = [deviceToken bytes];
         NSString *deviceTokenString = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                            ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                            ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                            ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
         NSLog(@"deviceToken:%@", deviceTokenString);
         [[RCIMClient sharedRCIMClient] setDeviceToken:deviceTokenString];
         /// Required - 注册 DeviceToken
         [JPUSHService registerDeviceToken:deviceToken];
     } else {
          NSString *deviceTokenString =
            [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"
                                                                   withString:@""]
              stringByReplacingOccurrencesOfString:@">"
              withString:@""]
             stringByReplacingOccurrencesOfString:@" "
             withString:@""];
            
            
            NSDictionary *user = [[NSUserDefaults standardUserDefaults] objectForKey:@"User"];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
            if (user) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self setiOSAlias];
                    [self setiOSTags];
                });
            }
            
            [[RCIMClient sharedRCIMClient] setDeviceToken:deviceTokenString];
            /// Required - 注册 DeviceToken
            [JPUSHService registerDeviceToken:deviceToken];
     }

 }
 
 4.控制器的 modalPresentationStyle 默认值变了
 在 iOS 13 UIModalPresentationStyle 枚举的定义中，苹果新加了一个枚举值：

 typedef NS_ENUM(NSInteger, UIModalPresentationStyle) {
     ...
     UIModalPresentationAutomatic API_AVAILABLE(ios(13.0)) = -2,
 };
 在 iOS 13 中此枚举值直接成为了模态弹出的默认值，因此 presentViewController 方式打开视图是下滑返回的视差效果。如果你完全接受苹果的这个默认效果，那就不需要去修改任何代码。如果你原来就比较细心，已经设置了modalPresentationStyle 的值，那你也不会有这个影响。对于想要找回原来默认交互的同学，直接设置如下即可：

 self.modalPresentationStyle = UIModalPresentationOverFullScreen;


 5.MPMoviePlayerController 被弃用
 在 iOS 9 之前播放视频可以使用 MediaPlayer.framework 中的MPMoviePlayerController类来完成，它支持本地视频和网络视频播放。但是在 iOS 9 开始被弃用，如果在 iOS 13 中继续使用的话会直接抛出异常：

 *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'MPMoviePlayerController is no longer available. Use AVPlayerViewController in AVKit.'

 解决方案是使用 AVFoundation 里的 AVPlayer。

 */


/* 使用蓝牙适配
 原因是iOS13 将废弃 NSBluetoothPeripheralUsageDescription 替换为NSBluetoothAlwaysUsageDescription
 
 解决方法，在 info.plist 中添加新字段

 <key> NSBluetoothAlwaysUsageDescription </key>
 <string>App需要您的同意,才能访问蓝牙</string>

 
 */
