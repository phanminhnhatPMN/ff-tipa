#import "PMNDevOverlay.h"

static bool g_isBox = true;
static bool g_isBone = true;
static bool g_isHealth = true;
static bool g_isName = true;
static bool g_isDistance = true;

static bool g_isAimbot = false;
static float g_aimFov = 160.0f;
static float g_aimDistance = 200.0f;

@interface PMNDevOverlayView ()
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) NSMutableArray<CALayer *> *espLayers;
@end

@implementation PMNDevOverlayView {
    UIView *m_floatingBtn;
    UIView *m_menuContainer;
    CGPoint m_touchPoint;

    UIView *m_tabESP;
    UIView *m_tabAim;
    UIView *m_tabLogs;

    UILabel *m_logLabel;
    
    pid_t m_pid;
    uint64_t m_base;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        self.espLayers = [NSMutableArray array];

        m_pid = -1;
        m_base = 0;

        [self buildFloatingButton];
        [self buildMenuUI];

        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onFrameUpdate)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)buildFloatingButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(30, 80, 60, 60);
    btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.0 blue:0.4 alpha:0.95];
    btn.layer.cornerRadius = 30;
    btn.layer.borderWidth = 3.0;
    btn.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0].CGColor;
    btn.clipsToBounds = YES;

    [btn setTitle:@"PMN" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
    [btn addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesture:)];
    [btn addGestureRecognizer:pan];

    m_floatingBtn = btn;
    [self addSubview:m_floatingBtn];
}

- (void)addSwitchRow:(UIView *)parent title:(NSString *)title y:(CGFloat)y val:(bool)val sel:(SEL)sel {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 180, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
    [parent addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(260, y, 51, 31)];
    sw.on = val;
    sw.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.6 alpha:1.0];
    [sw addTarget:self action:sel forControlEvents:UIControlEventValueChanged];
    [parent addSubview:sw];
}

- (void)buildMenuUI {
    CGFloat w = 580;
    CGFloat h = 360;

    m_menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    m_menuContainer.backgroundColor = [UIColor colorWithRed:0.06 green:0.06 blue:0.10 alpha:0.96];
    m_menuContainer.layer.cornerRadius = 18;
    m_menuContainer.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:0.8].CGColor;
    m_menuContainer.layer.borderWidth = 2.5;
    m_menuContainer.clipsToBounds = YES;
    m_menuContainer.hidden = YES;
    [self addSubview:m_menuContainer];

    // Header Bar
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 50)];
    header.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.16 alpha:1.0];
    [m_menuContainer addSubview:header];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 320, 30)];
    title.text = @"PMNDEV CHEAT ENGINE";
    title.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0];
    title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
    [header addSubview:title];

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(330, 16, 170, 20)];
    sub.text = @"v1.130.1 | By PMNDev";
    sub.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    sub.font = [UIFont systemFontOfSize:11];
    [header addSubview:sub];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(w - 42, 11, 28, 28);
    closeBtn.backgroundColor = [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:1.0];
    closeBtn.layer.cornerRadius = 14;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];

    UIPanGestureRecognizer *panHeader = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesture:)];
    [header addGestureRecognizer:panHeader];

    // Sidebar
    UIView *sidebar = [[UIView alloc] initWithFrame:CGRectMake(14, 62, 120, 284)];
    sidebar.backgroundColor = [UIColor colorWithRed:0.10 green:0.10 blue:0.16 alpha:1.0];
    sidebar.layer.cornerRadius = 14;
    [m_menuContainer addSubview:sidebar];

    NSArray *tabs = @[@"🎯 ESP", @"🔥 AIMBOT", @"⚙️ LOGS"];
    for (int i = 0; i < tabs.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(8, 14 + (i * 60), 104, 46);
        btn.backgroundColor = (i == 0) ? [UIColor colorWithRed:0.0 green:0.6 blue:0.6 alpha:1.0] : [UIColor colorWithRed:0.16 green:0.16 blue:0.24 alpha:1.0];
        [btn setTitle:tabs[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 10;
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        btn.tag = i;
        [btn addTarget:self action:@selector(onTabClicked:) forControlEvents:UIControlEventTouchUpInside];
        [sidebar addSubview:btn];
    }

    // --- TAB 1: ESP ---
    m_tabESP = [[UIView alloc] initWithFrame:CGRectMake(146, 62, 420, 284)];
    m_tabESP.backgroundColor = [UIColor clearColor];
    [m_menuContainer addSubview:m_tabESP];

    [self addSwitchRow:m_tabESP title:@"Box ESP" y:15 val:g_isBox sel:@selector(onToggleBox:)];
    [self addSwitchRow:m_tabESP title:@"Skeleton / Bone" y:60 val:g_isBone sel:@selector(onToggleBone:)];
    [self addSwitchRow:m_tabESP title:@"Health Bar" y:105 val:g_isHealth sel:@selector(onToggleHealth:)];
    [self addSwitchRow:m_tabESP title:@"Player Name" y:150 val:g_isName sel:@selector(onToggleName:)];
    [self addSwitchRow:m_tabESP title:@"Distance Meter" y:195 val:g_isDistance sel:@selector(onToggleDistance:)];

    // --- TAB 2: AIMBOT ---
    m_tabAim = [[UIView alloc] initWithFrame:CGRectMake(146, 62, 420, 284)];
    m_tabAim.backgroundColor = [UIColor clearColor];
    m_tabAim.hidden = YES;
    [m_menuContainer addSubview:m_tabAim];

    [self addSwitchRow:m_tabAim title:@"Auto Aimbot" y:15 val:g_isAimbot sel:@selector(onToggleAimbot:)];

    UILabel *fovLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, 250, 24)];
    fovLbl.text = @"FOV Radius (10 - 500):";
    fovLbl.textColor = [UIColor whiteColor];
    fovLbl.font = [UIFont systemFontOfSize:14];
    [m_tabAim addSubview:fovLbl];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(20, 100, 380, 30)];
    slider.minimumValue = 10;
    slider.maximumValue = 500;
    slider.value = g_aimFov;
    slider.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:1.0];
    [slider addTarget:self action:@selector(onFovChanged:) forControlEvents:UIControlEventValueChanged];
    [m_tabAim addSubview:slider];

    // --- TAB 3: LOGS ---
    m_tabLogs = [[UIView alloc] initWithFrame:CGRectMake(146, 62, 420, 284)];
    m_tabLogs.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.08 alpha:1.0];
    m_tabLogs.layer.cornerRadius = 12;
    m_tabLogs.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:0.5].CGColor;
    m_tabLogs.layer.borderWidth = 1.5;
    m_tabLogs.hidden = YES;
    [m_menuContainer addSubview:m_tabLogs];

    UILabel *logTitle = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 300, 24)];
    logTitle.text = @"PMNDEV SYSTEM CONSOLE LOGS";
    logTitle.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0];
    logTitle.font = [UIFont boldSystemFontOfSize:14];
    [m_tabLogs addSubview:logTitle];

    UIView *div = [[UIView alloc] initWithFrame:CGRectMake(15, 42, 390, 1)];
    div.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.8 alpha:0.5];
    [m_tabLogs addSubview:div];

    m_logLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 50, 390, 220)];
    m_logLabel.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.4 alpha:1.0];
    m_logLabel.font = [UIFont fontWithName:@"Courier" size:12];
    m_logLabel.numberOfLines = 0;
    m_logLabel.text = @"[PMNDEV ENGINE INITIALIZED]\nScanning game process...";
    [m_tabLogs addSubview:m_logLabel];

    CGRect screen = [UIScreen mainScreen].bounds;
    m_menuContainer.center = CGPointMake(screen.size.width / 2.0, screen.size.height / 2.0);
}

- (void)onTabClicked:(UIButton *)btn {
    m_tabESP.hidden = YES;
    m_tabAim.hidden = YES;
    m_tabLogs.hidden = YES;

    for (UIView *v in btn.superview.subviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *b = (UIButton *)v;
            b.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.24 alpha:1.0];
        }
    }
    btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.6 alpha:1.0];

    if (btn.tag == 0) m_tabESP.hidden = NO;
    if (btn.tag == 1) m_tabAim.hidden = NO;
    if (btn.tag == 2) m_tabLogs.hidden = NO;
}

- (void)onToggleBox:(UISwitch *)sw { g_isBox = sw.isOn; }
- (void)onToggleBone:(UISwitch *)sw { g_isBone = sw.isOn; }
- (void)onToggleHealth:(UISwitch *)sw { g_isHealth = sw.isOn; }
- (void)onToggleName:(UISwitch *)sw { g_isName = sw.isOn; }
- (void)onToggleDistance:(UISwitch *)sw { g_isDistance = sw.isOn; }
- (void)onToggleAimbot:(UISwitch *)sw { g_isAimbot = sw.isOn; }
- (void)onFovChanged:(UISlider *)sl { g_aimFov = sl.value; }

- (void)showMenu {
    m_menuContainer.hidden = NO;
    m_floatingBtn.hidden = YES;
    [self bringSubviewToFront:m_menuContainer];
}

- (void)hideMenu {
    m_menuContainer.hidden = YES;
    m_floatingBtn.hidden = NO;
    [self bringSubviewToFront:m_floatingBtn];
}

- (void)onPanGesture:(UIPanGestureRecognizer *)pan {
    CGPoint pt = [pan locationInView:self];
    if (pan.state == UIGestureRecognizerStateBegan) {
        m_touchPoint = pt;
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGFloat dx = pt.x - m_touchPoint.x;
        CGFloat dy = pt.y - m_touchPoint.y;
        UIView *v = (pan.view == m_floatingBtn) ? m_floatingBtn : m_menuContainer;
        v.center = CGPointMake(v.center.x + dx, v.center.y + dy);
        m_touchPoint = pt;
    }
}

- (void)onFrameUpdate {
    m_pid = GetGamePID();
    if (m_pid > 0) {
        m_base = GetGameModuleBase(m_pid);
    } else {
        m_base = 0;
    }

    if (m_logLabel) {
        NSString *statusStr = (m_pid > 0 && m_base > 0) ? @"CONNECTED YES (ONLINE)" : @"SEARCHING PROCESS...";
        m_logLabel.text = [NSString stringWithFormat:
            @"=== PMNDEV ENGINE SYSTEM STATUS ===\n"
            @"Developer: PMNDev (Tris)\n"
            @"Status: %@\n"
            @"Process PID: %d\n"
            @"Module Base: 0x%llX\n"
            @"GameFacade Offset: 0xC012848\n\n"
            @"=== ACTIVE ESP FEATURES ===\n"
            @"Box: %d | Bone: %d | Health: %d\n"
            @"Name: %d | Dist: %d | Aimbot: %d\n"
            @"Aim FOV: %.0f | Bone Offset: 0x630",
            statusStr, m_pid, m_base,
            g_isBox, g_isBone, g_isHealth,
            g_isName, g_isDistance, g_isAimbot, g_aimFov];
    }

    for (CALayer *layer in self.espLayers) {
        [layer removeFromSuperlayer];
    }
    [self.espLayers removeAllObjects];

    if (g_isAimbot) {
        CAShapeLayer *fovLayer = [CAShapeLayer layer];
        CGPoint center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:g_aimFov startAngle:0 endAngle:2 * M_PI clockwise:YES];
        fovLayer.path = path.CGPath;
        fovLayer.strokeColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:0.8].CGColor;
        fovLayer.fillColor = [UIColor clearColor].CGColor;
        fovLayer.lineWidth = 1.5;
        [self.espLayers addObject:fovLayer];
    }

    if (m_pid > 0 && m_base > 0) {
        uint64_t matchGame = GetMatchGame(m_base);
        if (matchGame > 0) {
            uint64_t localPlayer = GetLocalPlayer(matchGame);
            if (localPlayer > 0) {
                uint64_t myPawn = GetPawnObject(localPlayer);
                if (myPawn > 0) {
                    std::vector<uint64_t> enemies = GetEnemyList(matchGame);
                    for (uint64_t enemy : enemies) {
                        if (enemy == 0 || enemy == myPawn) continue;
                        if (GetIsDead(enemy)) continue;

                        Vector3 headPos = GetNodePosition(enemy, 0x630);
                        Vector3 hipPos = GetNodePosition(enemy, 0x638);
                        if (headPos.x == 0 && headPos.y == 0) continue;

                        Vector3 headScreen = WorldToScreen(headPos);
                        Vector3 hipScreen = WorldToScreen(hipPos);

                        float boxHeight = std::abs(hipScreen.y - headScreen.y) * 2.2f;
                        if (boxHeight < 15) boxHeight = 50;
                        float boxWidth = boxHeight * 0.55f;
                        float x = headScreen.x - (boxWidth / 2.0f);
                        float y = headScreen.y - (boxHeight * 0.15f);

                        if (g_isBox) {
                            CAShapeLayer *boxLayer = [CAShapeLayer layer];
                            UIBezierPath *boxPath = [UIBezierPath bezierPathWithRect:CGRectMake(x, y, boxWidth, boxHeight)];
                            boxLayer.path = boxPath.CGPath;
                            boxLayer.strokeColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0].CGColor;
                            boxLayer.fillColor = [UIColor clearColor].CGColor;
                            boxLayer.lineWidth = 1.5;
                            [self.espLayers addObject:boxLayer];
                        }

                        if (g_isName) {
                            CATextLayer *nameLayer = [CATextLayer layer];
                            nameLayer.string = @"[PMNDEV ENEMY]";
                            nameLayer.fontSize = 10;
                            nameLayer.frame = CGRectMake(x - 20, y - 16, boxWidth + 40, 14);
                            nameLayer.alignmentMode = kCAAlignmentCenter;
                            nameLayer.foregroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.8 alpha:1.0].CGColor;
                            [self.espLayers addObject:nameLayer];
                        }
                    }
                }
            }
        }
    }

    for (CALayer *layer in self.espLayers) {
        [self.layer addSublayer:layer];
    }
}

@end
