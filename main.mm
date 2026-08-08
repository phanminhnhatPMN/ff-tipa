#import <UIKit/UIKit.h>
#import "PMNDevOverlay.h"

// Initialize Overlay Window automatically upon HUD launch
__attribute__((constructor))
static void initializePMNDevHUDOverlay(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        static UIWindow *gPMNWindow = nil;
        CGRect frame = [UIScreen mainScreen].bounds;
        gPMNWindow = [[UIWindow alloc] initWithFrame:frame];
        gPMNWindow.windowLevel = UIWindowLevelStatusBar + 2000;
        gPMNWindow.backgroundColor = [UIColor clearColor];
        gPMNWindow.userInteractionEnabled = YES;

        PMNDevOverlayView *overlay = [[PMNDevOverlayView alloc] initWithFrame:frame];
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view = overlay;
        gPMNWindow.rootViewController = vc;
        gPMNWindow.hidden = NO;
    });
}

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, nil);
    }
}

