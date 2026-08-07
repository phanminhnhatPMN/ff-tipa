#import <UIKit/UIKit.h>
#import "PMNDevOverlay.h"

@interface PMNAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation PMNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    CGRect frame = [UIScreen mainScreen].bounds;
    self.window = [[UIWindow alloc] initWithFrame:frame];
    self.window.windowLevel = UIWindowLevelStatusBar + 5000;
    self.window.backgroundColor = [UIColor clearColor];
    self.window.userInteractionEnabled = YES;

    PMNDevOverlayView *overlay = [[PMNDevOverlayView alloc] initWithFrame:frame];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view = overlay;
    self.window.rootViewController = vc;
    self.window.hidden = NO;

    return YES;
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([PMNAppDelegate class]));
    }
}
