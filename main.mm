#import <UIKit/UIKit.h>
#import "PMNDevOverlay.h"

@interface PMNAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation PMNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGRect frame = [UIScreen mainScreen].bounds;
        self.window = [[UIWindow alloc] initWithFrame:frame];
        self.window.windowLevel = UIWindowLevelStatusBar + 2000;
        self.window.backgroundColor = [UIColor clearColor];
        self.window.userInteractionEnabled = YES;

        PMNDevOverlayView *overlay = [[PMNDevOverlayView alloc] initWithFrame:frame];
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view = overlay;
        self.window.rootViewController = vc;
        self.window.hidden = NO;
    });

    return YES;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([PMNAppDelegate class]));
    }
}
