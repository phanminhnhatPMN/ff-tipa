#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "PMNDevOverlay.h"

@interface UIWindow (Private)
- (unsigned int)_contextId;
@end

__attribute__((constructor))
static void initializePMNDevHUDOverlay(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        static UIWindow *gPMNWindow = nil;
        CGRect frame = [UIScreen mainScreen].bounds;
        gPMNWindow = [[UIWindow alloc] initWithFrame:frame];
        gPMNWindow.windowLevel = 10000010.0;
        gPMNWindow.backgroundColor = [UIColor clearColor];
        gPMNWindow.userInteractionEnabled = YES;

        PMNDevOverlayView *overlay = [[PMNDevOverlayView alloc] initWithFrame:frame];
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view = overlay;
        gPMNWindow.rootViewController = vc;
        gPMNWindow.hidden = NO;

        Class hostingCls = objc_getClass("SBSAccessibilityWindowHostingController");
        if (hostingCls) {
            id hostingController = [[hostingCls alloc] init];
            if ([gPMNWindow respondsToSelector:@selector(_contextId)]) {
                unsigned int contextId = [gPMNWindow _contextId];
                double level = 10000010.0;
                NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
                if (sig) {
                    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                    [inv setTarget:hostingController];
                    [inv setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
                    [inv setArgument:&contextId atIndex:2];
                    [inv setArgument:&level atIndex:3];
                    [inv invoke];
                }
            }
        }
    });
}




