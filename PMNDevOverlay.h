#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GameLogic.h"
#import "Memory.h"

@interface PMNDevOverlayView : UIView

- (instancetype)initWithFrame:(CGRect)frame;
- (void)showMenu;
- (void)hideMenu;

@end
