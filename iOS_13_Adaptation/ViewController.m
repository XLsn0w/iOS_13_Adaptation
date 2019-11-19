//
//  ViewController.m
//  iOS_13_Adaptation
//
//  Created by mac on 2019/11/19.
//  Copyright © 2019 XLsn0w. All rights reserved.
/*
 前言：随着iPhone 11的发布，iOS 13已经开始正式使用。每年发布新系统，都会带来一些新的变化，之前的一些方法的废弃，又新增一些新的方法等等。因此作为应用开发者，为了让我们的应用能在新的系统上流畅运行，不出问题，就需要对新系统进行全方位的适配。本文将全面介绍即将到来的iOS 13系统上的一些注意点和新增的黑暗模式，我们的应用怎么去适配。

 一：iOS 13系统的适配以及变化
 1.私有KVC

 iOS 13上不允许使用：valueForKey、setValue: forKey获取和设置私有属性，需要使用其它方式修改,不然会奔溃
 如：

 [textField setValue:[UIColor red] forKeyPath:@"_placeholderLabel.textColor"];
 //UITextField有个attributedPlaceholder的属性，我们可以自定义这个富文本来达到我们需要的结果，替换为
 textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"输入"attributes:@{NSForegroundColorAttributeName: [UIColor red]}];

 iOS 13 通过 KVC 方式修改私有属性，有 Crash 风险，谨慎使用！并不是所有KVC都会Crash，要尝试！

 2.通过计算TabBar上的图片位置设置红点，红点位置有偏移

 如果之前有通过TabBar上图片位置来设置红点位置，在iOS13上会发现显示位置都在最左边去了。遍历UITabBarButton的subViews发现只有在TabBar选中状态下才能取到UITabBarSwappableImageView，解决办法是修改为通过UITabBarButton的位置来设置红点的frame。

 3.模态弹出默认交互改变

 Defines the presentation style that will be used for this view controller when it is presented modally. Set this property on the view controller to be presented, not the presenter.
 If this property has been set to UIModalPresentationAutomatic, reading it will always return a concrete presentation style. By default UIViewController resolves UIModalPresentationAutomatic to UIModalPresentationPageSheet, but other system-provided view controllers may resolve UIModalPresentationAutomatic to other concrete presentation styles.

 iOS 13 的 presentViewController 默认有视差效果，模态出来的界面现在默认都下滑返回。 一些页面必须要点确认才能消失的，需要适配。如果项目中页面高度全部是屏幕尺寸，那么多出来的导航高度会出现问题。

 控制器的 modalPresentationStyle 默认值变了：

 查阅了下 UIModalPresentationStyle枚举定义，赫然发现iOS 13新加了一个枚举值：
 typedef NS_ENUM(NSInteger, UIModalPresentationStyle) {
     UIModalPresentationFullScreen = 0,
     UIModalPresentationPageSheet API_AVAILABLE(ios(3.2)) API_UNAVAILABLE(tvos),
     UIModalPresentationFormSheet API_AVAILABLE(ios(3.2)) API_UNAVAILABLE(tvos),
     UIModalPresentationCurrentContext API_AVAILABLE(ios(3.2)),
     UIModalPresentationCustom API_AVAILABLE(ios(7.0)),
     UIModalPresentationOverFullScreen API_AVAILABLE(ios(8.0)),
     UIModalPresentationOverCurrentContext API_AVAILABLE(ios(8.0)),
     UIModalPresentationPopover API_AVAILABLE(ios(8.0)) API_UNAVAILABLE(tvos),
     UIModalPresentationBlurOverFullScreen API_AVAILABLE(tvos(11.0)) API_UNAVAILABLE(ios) API_UNAVAILABLE(watchos),
     UIModalPresentationNone API_AVAILABLE(ios(7.0)) = -1,
     UIModalPresentationAutomatic API_AVAILABLE(ios(13.0)) = -2,
 };

 如果你完全接受苹果的这个默认效果，那就不需要去修改任何代码。
 如果，你原来就比较细心，已经设置了modalPresentationStyle的值，那你也不会有这个影响。
 对于想要找回原来默认交互的同学，直接设置如下即可：

 self.modalPresentationStyle = UIModalPresentationOverFullScreen;
 4.MPMoviePlayerController 在iOS 13已经不能用了

 'MPMoviePlayerController is no longer available. Use AVPlayerViewController in AVKit.'
 既然不能用了，就只能使用其他播放器了
 5.UISearchBar显示问题
 升级到iOS13，UISearchController上的SearchBar显示异常，查看后发现对应的高度只有1px,目前没找到具体导致的原因，解决办法是使用KVO监听frame值变化后设置去应该显示的高度,另外，也可能出现一些其他的显示问题，这个需要自己去一个个查看，在去解决相应的问题。

 黑线处理crash
 之前为了处理搜索框的黑线问题会遍历后删除UISearchBarBackground，在iOS13会导致UI渲染失败crash;解决办法是设置UISearchBarBackground的layer.contents为nil

 public func clearBlackLine() {
         for view in self.subviews.last!.subviews {
             if view.isKind(of: NSClassFromString("UISearchBarBackground")!) {
                 view.backgroundColor = UIColor.white
                 view.layer.contents = nil
                 break
             }
         }
     }
 6.iOS 13 DeviceToken有变化

 NSString *dt = [deviceToken description];
 dt = [dt stringByReplacingOccurrencesOfString: @"<" withString: @""];
 dt = [dt stringByReplacingOccurrencesOfString: @">" withString: @""];
 dt = [dt stringByReplacingOccurrencesOfString: @" " withString: @""];
 这段代码运行在 iOS 13 上已经无法获取到准确的DeviceToken字符串了，
 iOS 13 通过[deviceToken description]获取到的内容已经变了。

 解决方案：
 - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
 {
     if (![deviceToken isKindOfClass:[NSData class]]) return;
     const unsigned *tokenBytes = [deviceToken bytes];
     NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                           ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                           ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                           ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
     NSLog(@"deviceToken:%@",hexToken);
 }

 7.提供第三方登录的注意啦

 Sign In with Apple will be available for beta testing this summer. It will be required as an option for users in apps that support third-party sign-in when it is commercially available later this year.

 如果 APP 支持三方登陆（Facbook、Google、微信、QQ、支付宝等），就必须支持苹果登陆，且要放前边。关于苹果登录的，大家可以自行百度: ASAuthorizationAppleIDButton这个关键词，进行具体的查看

 对于非iOS平台，Web、Android 可以使用 JS SDK，网页版本登录，逻辑类似、Facebook、QQ登录。

 建议支持使用Apple提供的按钮样式，已经适配各类设备。个人理解苹果的大概意思应该是，使用第三方登录的应用，都要提供苹果登录这个模式，如果不提供，那么在审核的时候，审核应该不给通过。

 8.即将废弃的 LaunchImage

 从 iOS 8 的时候，苹果就引入了 LaunchScreen，我们可以设置 LaunchScreen来作为启动页。当然，现在你还可以使用LaunchImage来设置启动图。不过使用LaunchImage的话，要求我们必须提供各种屏幕尺寸的启动图，来适配各种设备，随着苹果设备尺寸越来越多，这种方式显然不够 Flexible。而使用 LaunchScreen的话，情况会变的很简单， LaunchScreen是支持AutoLayout+SizeClass的，所以适配各种屏幕都不在话下。
 注意啦⚠️，从2020年4月开始，所有使⽤ iOS13 SDK的 App将必须提供 LaunchScreen，LaunchImage即将退出历史舞台。
 9. Status Bar(状态栏)更新

 iOS13对Status BarAPI做了修改
 之前Status Bar有两种状态：
 UIStatusBarStyleDefault 文字黑色
 UIStatusBarStyleLightContent 文字白色


 iOS13以前Status Bar样式
 iOS13以后有三种状态：
 UIStatusBarStyleDefault自动选择黑色或白色
 UIStatusBarStyleDarkContent文字黑色
 UIStatusBarStyleLightContent文字白色


 iOS13以后Status Bar有三种状态
 10.UIActivityIndicatorView加载视图

 iOS13对UIActivityIndicatorView的样式也做了修改
 之前有三种样式:
 UIActivityIndicatorViewStyleGray 灰色
 UIActivityIndicatorViewStyleWhite 白色
 UIActivityIndicatorViewStyleWhiteLarge 白色(大型)
 iOS13废弃了以上三种样式，而用以下两种样式代替:
 UIActivityIndicatorViewStyleLarge (大型)
 UIActivityIndicatorViewStyleMedium （中型）
 iOS13通过color属性设置其颜色

 示例:

 - (UIActivityIndicatorView *)loadingView {
     if (_loadingView == nil) {
         _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
         [_loadingView setColor:[UIColor systemBackgroundColor]];
         [_loadingView setFrame:CGRectMake(0, 0, 200, 200)];
         [_loadingView setCenter:self.view.center];
     }
     return _loadingView;
 }
 效果:


 iOS13之前的三种样式
 iOS13以后的两种样式
 现在，我们来看看，在iOS 13系统新增的最重大的功能，就是黑暗模式，苹果自己叫深色模式：Dark Mode：

 Apps on iOS 13 are expected to support dark mode Use system colors and materials Create your own dynamic colors and images Leverage flexible infrastructure
 Apps on iOS 13 are expected to support dark mode Use system colors and materials

 查看了网上有些人说，iOS 13系统上，必须要适配黑暗模式，不然审核是通不过的，但我看了苹果自己的说明，我个人的理解意思是，这个不是强制要求，开发者可以自己选。好了，继续往下看这个，下来会根据以下几个方面讲解黑暗模式：

 一、适配Dark Mode：颜色适配，图片适配
 二、获取当前模式(Light or Dark)
 三、其他内容
 四、总结

 首先看看我们的效果图:


 image.png
 一、适配Dark Mode
 开发者主要从颜色和图片两个方面进行适配，我们不需要关心切换模式时该如何操作，这些都由系统帮我们实现

 颜色适配：
 iOS13 之前 UIColor只能表示一种颜色，而从 iOS13 开始UIColor是一个动态的颜色，在Light Mode和Dark Mode可以分别设置不同的颜色。
 iOS13系统提供了一些动态颜色
 @property (class, nonatomic, readonly) UIColor *systemBrownColor        API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *systemIndigoColor       API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *systemGray2Color        API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *systemGray3Color        API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *systemGray4Color        API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *systemGray5Color        API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *systemGray6Color        API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *labelColor              API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *secondaryLabelColor     API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *tertiaryLabelColor      API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *quaternaryLabelColor    API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *linkColor               API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *placeholderTextColor    API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *separatorColor          API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *opaqueSeparatorColor    API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 @property (class, nonatomic, readonly) UIColor *systemBackgroundColor                   API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *secondarySystemBackgroundColor          API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *tertiarySystemBackgroundColor           API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *systemGroupedBackgroundColor            API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *secondarySystemGroupedBackgroundColor   API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *tertiarySystemGroupedBackgroundColor    API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *systemFillColor                         API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *secondarySystemFillColor                API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *tertiarySystemFillColor                 API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 @property (class, nonatomic, readonly) UIColor *quaternarySystemFillColor               API_AVAILABLE(ios(13.0)) API_UNAVAILABLE(tvos, watchos);
 ① 实例:


 [self.view setBackgroundColor:[UIColor systemBackgroundColor]];
 [self.titleLabel setTextColor:[UIColor labelColor]];
 [self.detailLabel setTextColor:[UIColor placeholderTextColor]];
 ② 效果展示:


 系统UIColor样式

 用法和iOS13之前的一样，使用系统提供的这些动态颜色，不需要其他的适配操作

 ③ 自定义动态UIColor
 在实际开发过程，系统提供的这些颜色还远远不够，因此我们需要创建更多的动态颜色
 初始化动态UIColor方法
 iOS13 UIColor增加了两个初始化方法，使用以下方法可以创建动态UIColor
 注:一个是类方法，一个是实例方法


 + (UIColor *)colorWithDynamicProvider:(UIColor * (^)(UITraitCollection *))dynamicProvider API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 - (UIColor *)initWithDynamicProvider:(UIColor * (^)(UITraitCollection *))dynamicProvider API_AVAILABLE(ios(13.0), tvos(13.0)) API_UNAVAILABLE(watchos);
 这两个方法要求传一个block进去
 当系统在LightMode和DarkMode之间相互切换时就会触发此回调
 这个block会返回一个UITraitCollection类
 我们需要使用其属性userInterfaceStyle，它是一个枚举类型，会告诉我们当前是LightMode还是DarkMode

 typedef NS_ENUM(NSInteger, UIUserInterfaceStyle) {
     UIUserInterfaceStyleUnspecified,
     UIUserInterfaceStyleLight,
     UIUserInterfaceStyleDark,
 } API_AVAILABLE(tvos(10.0)) API_AVAILABLE(ios(12.0)) API_UNAVAILABLE(watchos);
 实例:

 UIColor *dyColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trainCollection) {
         if ([trainCollection userInterfaceStyle] == UIUserInterfaceStyleLight) {
             return [UIColor redColor];
         }
         else {
             return [UIColor greenColor];
         }
     }];
     
  [self.bgView setBackgroundColor:dyColor];
 效果展示:


 自定义UIColor效果
 接下来我们看看如何适配图片:

 2.图片适配
 打开Assets.xcassets
 新建一个Image set

 默认显示效果
 打开右侧工具栏，点击最后一栏，找到Appearances，选择Any，Dark


 侧边栏

 将两种模式下不同的图片资源都拖进去


 两种不同模式

 使用该图片:
 [_logoImage setImage:[UIImage imageNamed:@"icon_logo"]];
 最终效果图
 大功告成，完成颜色和图片的Dark Mode适配，是不是很easy呢!

 获取当前模式(Light or Dark)
 有时候我们需要知道当前处于什么模式，并根据不同的模式执行不同的操作
 iOS13中CGColor依然只能表示单一的颜色
 通过调用UITraitCollection.currentTraitCollection.userInterfaceStyle
 获取当前模式
 实例:

 if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
         [self.titleLabel setText:@"DarkMode"];
     }
     else {
         [self.titleLabel setText:@"LightMode"];
     }
 其他
 1.监听模式切换
 有时我们需要监听系统模式的变化，并作出响应
 那么我们就需要在需要监听的viewController中，重写下列函数

 / 注意:参数为变化前的traitCollection
 - (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection;

 // 判断两个UITraitCollection对象是否不同
 - (BOOL)hasDifferentColorAppearanceComparedToTraitCollection:(UITraitCollection *)traitCollection;
 示例:


 - (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
     [super traitCollectionDidChange:previousTraitCollection];
     // trait发生了改变
     if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
     // 执行操作
     }
     }
 2.CGColor适配

 我们知道iOS13后，UIColor能够表示动态颜色，但是CGColor依然只能表示一种颜色，那么对于CALayer等对象如何适配暗黑模式呢?当然是利用前面提到的监听模式切换的方法啦。

 方式一:resolvedColor

 // 通过当前traitCollection得到对应UIColor
 // 将UIColor转换为CGColor
 - (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traitCollection;
 实例:

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
 方式二:performAsCurrent

 // 使用当前trainCollection调用此方法
 - (void)performAsCurrentTraitCollection:(void (^)(void))actions;
 示例:

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
 方式三:最简单的方法,直接设置为一个动态UIColor的CGColor即可

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
 ⚠️!!! 设置layer颜色都是在traitCollectionDidChange中，意味着如果没有发生模式切换，layer将会没有颜色，需要设置一个基本颜色

 3.模式切换时打印log
 模式切换时自动打印log，就不需要我们一次又一次的执行po命令了
 在Xcode菜单栏Product->Scheme->Edit Scheme
 选择Run->Arguments->Arguments Passed On Launch
 添加以下命令即可:
 -UITraitCollectionChangeLoggingEnabled YES


 模式切换打印log

 4.强行设置App模式

 当系统设置为Light Mode时，对某些App的个别页面希望一直显示Dark Mode下的样式，这个时候就需要强行设置当前ViewController的模式了

 // 设置当前view或viewCongtroller的模式
 @property(nonatomic) UIUserInterfaceStyle overrideUserInterfaceStyle;
 示例:

 // 设置为Dark Mode即可
 [self setOverrideUserInterfaceStyle:UIUserInterfaceStyleDark];
 ⚠️ 注意!!!
 当我们强行设置当前viewController为Dark Mode后，这个viewController下的view都是Dark Mode
 由这个ViewController present出的ViewController不会受到影响，依然跟随系统的模式，
 不想适配暗黑模式可以关闭暗黑模式：
 在Info.plist文件中添加Key:User Interface Style，值类型设置为String,值为Light，就可以不管在什么模式下，软件只支持浅色模式，不支持黑暗模式，如果只想软件支持黑暗模式，则可以把类型设置为：Dark

 5.NSAttributedString优化:
 对于UILabel、UITextField、UITextView，在设置NSAttributedString时也要考虑适配Dark Mode，否则在切换模式时会与背景色融合，造成不好的体验
 不建议的做法:

 NSDictionary *dic = @{NSFontAttributeName:[UIFont systemFontOfSize:16]};
 NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"富文本文案" attributes:dic];
 推荐的做法:

 // 添加一个NSForegroundColorAttributeName属性
 NSDictionary *dic = @{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor labelColor]};
 NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"富文本文案" attributes:dic];
 6.iOS13 中设置 UITabBarItem的选中以及未选中字体颜色无效

 iOS13 碰到设置tabbar字体为选中状态颜色，正常切换没有问题，push后再返回，选中颜色变化系统蓝色，以及其他未选中的字体颜色也变为系统的蓝牙
 目前碰到这种状况有两种方法：
 这个是子视图影响所以用tintColor试试
 tintColor有寻找和传递
 1、寻找也就是通过get方法获取属性的值。
 2、传递也就是当主动改变tintColor时
 解决办法如下,在iOS 13上面可以用以下方法设置字体颜色，其他系统可以保持原来的设置方法不变：

 if (@available(iOS 13, *)) {
  self.tabBar.unselectedItemTintColor = [UIColor whiteColor]; //未选中字体的颜色
   self.tabBar.tintColor =  [UIColor whiteColor]; //选中字体的颜色
 } else {
 // Fallback on earlier versions
 }


 */

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


@end
