// SettingsView.mm

#import <objc/runtime.h>
#import "SettingsView.h"

#define kDefaultCornerRadius 14.0f
#define kDefaultAnimationDuration 0.35f
#define kHeaderHeight 44.0f
#define kDefaultLabelFontSize 15.0f
#define kDefaultComponentHeight 44.0f
#define kSliderTextFieldWidth 60.0f

NSString * const kSettingsViewSelectedThemeKey = @"SettingsViewSelectedThemeKey";

static void * const kMenuComponentAssociatedKey = (void *)&kMenuComponentAssociatedKey;
static void * const kSliderAssociatedKey = (void *)&kSliderAssociatedKey;
static void * const kComponentViewAssociatedKey = (void *)&kComponentViewAssociatedKey;

@implementation MenuComponent
- (instancetype)init {
    self = [super init];
    if (self) {
        _labelFontSize = kDefaultLabelFontSize;
        _labelAlignment = NSTextAlignmentLeft;
        _labelFontWeight = UIFontWeightRegular;
        _selectedIndex = -1;
    }
    return self;
}
+ (instancetype)sliderComponentWithTitle:(NSString *)title key:(NSString *)key min:(CGFloat)min max:(CGFloat)max initial:(CGFloat)initial {
    MenuComponent *comp = [[MenuComponent alloc] init];
    comp.type = MenuComponentTypeSlider;
    comp.title = title;
    comp.key = key;
    comp.minValue = min;
    comp.maxValue = max;
    if (key && [[NSUserDefaults standardUserDefaults] objectForKey:key]) {
        comp.currentValue = [[NSUserDefaults standardUserDefaults] floatForKey:key];
        comp.currentValue = MAX(min, MIN(max, comp.currentValue));
    } else {
        comp.currentValue = initial;
    }
    return comp;
}
+ (instancetype)switchComponentWithTitle:(NSString *)title key:(NSString *)key initial:(BOOL)initial {
    MenuComponent *comp = [[MenuComponent alloc] init];
    comp.type = MenuComponentTypeSwitch;
    comp.title = title;
    comp.key = key;
    if (key && [[NSUserDefaults standardUserDefaults] objectForKey:key]) {
        comp.switchValue = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    } else {
        comp.switchValue = initial;
    }
    return comp;
}
+ (instancetype)sliderWithSwitchComponentWithTitle:(NSString *)title key:(NSString *)key min:(CGFloat)min max:(CGFloat)max initial:(CGFloat)initial switchInitial:(BOOL)switchInitial {
    MenuComponent *comp = [[MenuComponent alloc] init];
    comp.type = MenuComponentTypeSliderWithSwitch;
    comp.title = title;
    comp.key = key;
    NSString *sliderPartKey = [NSString stringWithFormat:@"%@_SliderValue", key];
    if (key && [[NSUserDefaults standardUserDefaults] objectForKey:key]) {
        comp.switchValue = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    } else {
        comp.switchValue = switchInitial;
    }
    comp.minValue = min;
    comp.maxValue = max;
    if (key && [[NSUserDefaults standardUserDefaults] objectForKey:sliderPartKey]) {
        comp.currentValue = [[NSUserDefaults standardUserDefaults] floatForKey:sliderPartKey];
        comp.currentValue = MAX(min, MIN(max, comp.currentValue));
    } else {
        comp.currentValue = initial;
    }
    return comp;
}
+ (instancetype)labelComponentWithText:(NSString *)text {
    return [self labelComponentWithText:text fontSize:kDefaultLabelFontSize alignment:NSTextAlignmentLeft fontWeight:UIFontWeightRegular];
}
+ (instancetype)labelComponentWithText:(NSString *)text
                              fontSize:(CGFloat)fontSize
                             alignment:(NSTextAlignment)alignment
                            fontWeight:(UIFontWeight)fontWeight {
    MenuComponent *comp = [[MenuComponent alloc] init];
    comp.type = MenuComponentTypeLabel;
    comp.title = text;
    comp.key = nil;
    comp.labelFontSize = fontSize;
    comp.labelAlignment = alignment;
    comp.labelFontWeight = fontWeight;
    return comp;
}
+ (instancetype)dropdownComponentWithTitle:(NSString *)title
                                       key:(NSString *)key
                                   options:(NSArray<NSString *> *)options
                           initialSelected:(NSInteger)initialSelected {
    MenuComponent *comp = [[MenuComponent alloc] init];
    comp.type = MenuComponentTypeDropdown;
    comp.title = title;
    comp.key = key;
    comp.options = options ?: @[];
    if (key && [[NSUserDefaults standardUserDefaults] objectForKey:key]) {
        comp.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:key];
    } else {
        comp.selectedIndex = initialSelected;
    }
    if (comp.selectedIndex < 0 || comp.selectedIndex >= comp.options.count) {
        comp.selectedIndex = (comp.options.count > 0) ? 0 : -1;
    }
    return comp;
}
+ (instancetype)themeSelectorComponentWithTitle:(NSString *)title
                                            key:(NSString *)key
                                initialSelected:(ThemeIdentifier)initialSelected {
    MenuComponent *comp = [[MenuComponent alloc] init];
    comp.type = MenuComponentTypeThemeSelector;
    comp.title = title;
    comp.key = key;
    comp.options = @[@"Mặc định", @"Xanh dương", @"Hồng"];
    ThemeIdentifier savedThemeId = initialSelected;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kSettingsViewSelectedThemeKey]) {
        NSInteger storedId = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsViewSelectedThemeKey];
        if (storedId >= ThemeIdentifierDefault && storedId <= ThemeIdentifierPink) {
            savedThemeId = (ThemeIdentifier)storedId;
        }
    }
    comp.selectedIndex = savedThemeId;
    return comp;
}
@end

@implementation MenuTab
- (instancetype)init {
    self = [super init];
    if (self) { _components = [NSMutableArray array]; }
    return self;
}
@end

@interface SettingsView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UISegmentedControl *tabControl;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) NSMutableArray<UIView *> *componentViews;
@property (nonatomic, strong, readwrite) UIView *headerDragView;
@property (nonatomic, strong, readwrite) UILabel *creditsLabel;
@property (nonatomic, assign) CGPoint lastKnownContainerCenter;
@property (nonatomic, assign) BOOL hasBeenDraggedOrInitiallyPositioned;
@property (nonatomic, strong, nullable) UIPickerView *activePickerView;
@property (nonatomic, strong, nullable) UIView *pickerContainerView;
@property (nonatomic, weak, nullable) MenuComponent *activeDropdownComponent;
@property (nonatomic, assign) ThemeIdentifier currentAppliedThemeIdentifier;
@property (nonatomic, strong) NSDictionary<NSString *, id> *currentThemeStyle;
@end

@implementation SettingsView
@synthesize delegate;

static SettingsView *instance = nil;
+ (void)load {
    [super load];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!instance) {
            instance = [[SettingsView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
    });
}

+ (instancetype)shared {
    if (instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [[SettingsView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        });
    }
    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _tabs = [NSMutableArray array];
        _selectedTabIndex = 0;
        _componentViews = [NSMutableArray array];
        _lastKnownContainerCenter = CGPointZero;
        _hasBeenDraggedOrInitiallyPositioned = NO;
        [self loadAndApplyInitialTheme];
        [self setupContainerView];
        [self setupHeaderDragView];
        [self setupBlurEffect];
        [self setupCloseButton];
        [self setupCreditsLabel];
        [self setupTabControl];
        [self setupScrollView];
        [self setupGestures];
        if (CGPointEqualToPoint(_lastKnownContainerCenter, CGPointZero)) {
            _lastKnownContainerCenter = _containerView.center;
        }
        [self setupCustomGestureToShow];
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self applyTheme:self.currentAppliedThemeIdentifier];
        }
    }
}

- (void)setCreditsText:(NSString * _Nullable)text {
    self.creditsLabel.text = text ?: kSettingsViewMadeByTextDefault;
}

- (void)loadAndApplyInitialTheme {
    ThemeIdentifier savedThemeId = ThemeIdentifierDefault;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kSettingsViewSelectedThemeKey]) {
        savedThemeId = (ThemeIdentifier)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsViewSelectedThemeKey];
        if (savedThemeId < ThemeIdentifierDefault || savedThemeId > ThemeIdentifierPink) {
            savedThemeId = ThemeIdentifierDefault;
        }
    }
    [self applyTheme:savedThemeId];
}

- (void)applyTheme:(ThemeIdentifier)themeIdentifier {
    self.currentAppliedThemeIdentifier = themeIdentifier;
    BOOL isDarkMode = NO;
    if (@available(iOS 12.0, *)) {
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            isDarkMode = YES;
        }
    }
    UIColor *primaryAccent, *secondaryText, *sliderTrack, *textFieldBg, *switchOnTint, *buttonText, *viewBackgroundAlpha, *headerBackgroundAlpha;
    UIBlurEffectStyle blurStyle;
    switch (themeIdentifier) {
        case ThemeIdentifierBlue:
            primaryAccent = [self colorFromHexString:@"a2d2ff"];
            if (isDarkMode) {
                viewBackgroundAlpha = [[self colorFromHexString:@"1D2D3E"] colorWithAlphaComponent:0.92];
                headerBackgroundAlpha = [[self colorFromHexString:@"2A3B4D"] colorWithAlphaComponent:0.8];
                secondaryText = [UIColor whiteColor]; buttonText = primaryAccent; blurStyle = UIBlurEffectStyleDark;
            } else {
                viewBackgroundAlpha = [[self colorFromHexString:@"E0F2FE"] colorWithAlphaComponent:0.95];
                headerBackgroundAlpha = [[self colorFromHexString:@"B9E2FA"] colorWithAlphaComponent:0.85];
                secondaryText = [self colorFromHexString:@"075985"]; buttonText = [self colorFromHexString:@"075985"]; blurStyle = UIBlurEffectStyleExtraLight;
            }
            sliderTrack = primaryAccent;
            textFieldBg = isDarkMode ? [[self colorFromHexString:@"374151"] colorWithAlphaComponent:0.7] : [[self colorFromHexString:@"BFDBFE"] colorWithAlphaComponent:0.7];
            switchOnTint = primaryAccent;
            break;
        case ThemeIdentifierPink:
            primaryAccent = [self colorFromHexString:@"ffafcc"];
            if (isDarkMode) {
                viewBackgroundAlpha = [[self colorFromHexString:@"4A1C31"] colorWithAlphaComponent:0.92];
                headerBackgroundAlpha = [[self colorFromHexString:@"59253C"] colorWithAlphaComponent:0.8];
                secondaryText = [UIColor whiteColor]; buttonText = primaryAccent; blurStyle = UIBlurEffectStyleDark;
            } else {
                viewBackgroundAlpha = [[self colorFromHexString:@"FCE7F3"] colorWithAlphaComponent:0.95];
                headerBackgroundAlpha = [[self colorFromHexString:@"FBCFE8"] colorWithAlphaComponent:0.85];
                secondaryText = [self colorFromHexString:@"9D174D"]; buttonText = [self colorFromHexString:@"9D174D"]; blurStyle = UIBlurEffectStyleExtraLight;
            }
            sliderTrack = primaryAccent;
            textFieldBg = isDarkMode ? [[self colorFromHexString:@"581C37"] colorWithAlphaComponent:0.7] : [[self colorFromHexString:@"F9A8D4"] colorWithAlphaComponent:0.7];
            switchOnTint = primaryAccent;
            break;
        case ThemeIdentifierDefault:
        default:
            if (isDarkMode) {
                viewBackgroundAlpha = [[UIColor blackColor] colorWithAlphaComponent:0.75];
                headerBackgroundAlpha = [[UIColor blackColor] colorWithAlphaComponent:0.65];
                primaryAccent = [UIColor systemBlueColor]; secondaryText = [UIColor lightGrayColor];
                sliderTrack = [UIColor systemBlueColor]; textFieldBg = [UIColor colorWithWhite:0.18 alpha:0.7];
                switchOnTint = [UIColor systemGreenColor]; buttonText = [UIColor systemBlueColor]; blurStyle = UIBlurEffectStyleDark;
            } else {
                viewBackgroundAlpha = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
                headerBackgroundAlpha = [[UIColor whiteColor] colorWithAlphaComponent:0.75];
                primaryAccent = [UIColor systemBlueColor]; secondaryText = [UIColor darkGrayColor];
                sliderTrack = [UIColor systemBlueColor]; textFieldBg = [UIColor colorWithWhite:0.92 alpha:0.7];
                switchOnTint = [UIColor systemGreenColor]; buttonText = [UIColor systemBlueColor]; blurStyle = UIBlurEffectStyleExtraLight;
            }
            break;
    }
    self.currentThemeStyle = @{
        @"primaryAccent": primaryAccent, @"secondaryText": secondaryText,
        @"sliderTrack": sliderTrack, @"textFieldBackground": textFieldBg,
        @"switchOnTint": switchOnTint, @"buttonText": buttonText,
        @"viewBackgroundAlpha": viewBackgroundAlpha, @"headerBackgroundAlpha": headerBackgroundAlpha,
        @"blurStyle": @(blurStyle)
    };
    if (_containerView) _containerView.backgroundColor = viewBackgroundAlpha;
    if (_blurView) _blurView.effect = [UIBlurEffect effectWithStyle:blurStyle];
    if (_headerDragView) _headerDragView.backgroundColor = headerBackgroundAlpha;
    if (_creditsLabel) _creditsLabel.textColor = [secondaryText colorWithAlphaComponent:0.8];
    if (_closeButton) _closeButton.tintColor = secondaryText;
    if (_tabControl) {
        if (@available(iOS 13.0, *)) {
            _tabControl.selectedSegmentTintColor = primaryAccent;
            [_tabControl setTitleTextAttributes:@{NSForegroundColorAttributeName: secondaryText} forState:UIControlStateNormal];
            [_tabControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [self contrastingColorForBackgroundColor:primaryAccent]} forState:UIControlStateSelected];
        } else {
            _tabControl.tintColor = primaryAccent;
        }
    }
    if (self.superview && self.tabs.count > 0) {
        [self reloadTabContent];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(themeChanged:)]) {
        [self.delegate themeChanged:themeIdentifier];
    }
}

- (UIColor *)contrastingColorForBackgroundColor:(UIColor *)backgroundColor {
    CGFloat r, g, b, a; [backgroundColor getRed:&r green:&g blue:&b alpha:&a];
    CGFloat yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000.0;
    return (yiq >= 0.5) ? [UIColor blackColor] : [UIColor whiteColor];
}

- (ThemeIdentifier)currentThemeIdentifier {
    return self.currentAppliedThemeIdentifier;
}

- (UIColor *)colorFromHexString:(NSString *)hexString alpha:(CGFloat)alpha {
    unsigned rgbValue = 0; NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString hasPrefix:@"#"]) {
        scanner.scanLocation = 1;
    }
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    return [self colorFromHexString:hexString alpha:1.0];
}

- (void)setupContainerView {
    CGFloat screenWidth = self.bounds.size.width;
    CGFloat screenHeight = self.bounds.size.height;
    CGFloat width = MIN(screenWidth * 0.9, 400);
    CGFloat height = MIN(screenHeight * 0.8, 700);
    _containerView = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - width) / 2, (screenHeight - height) / 2, width, height)];
    _containerView.backgroundColor = self.currentThemeStyle[@"viewBackgroundAlpha"] ?: [UIColor clearColor];
    _containerView.layer.cornerRadius = kDefaultCornerRadius;
    _containerView.layer.masksToBounds = YES;
    _containerView.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.2].CGColor;
    _containerView.layer.borderWidth = 0.5f;
    [self addSubview:_containerView];
    self.lastKnownContainerCenter = _containerView.center;
    self.hasBeenDraggedOrInitiallyPositioned = YES;
}

- (void)setupHeaderDragView {
    _headerDragView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _containerView.bounds.size.width, kHeaderHeight)];
    _headerDragView.backgroundColor = self.currentThemeStyle[@"headerBackgroundAlpha"] ?: [UIColor colorWithWhite:0.1 alpha:0.2];
    _headerDragView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_containerView addSubview:_headerDragView];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panContainer:)];
    [_headerDragView addGestureRecognizer:pan];
}

- (void)setupBlurEffect {
    UIBlurEffectStyle blurStyle = (UIBlurEffectStyle)[self.currentThemeStyle[@"blurStyle"] integerValue];
    _blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:blurStyle]];
    _blurView.frame = _containerView.bounds;
    _blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_containerView insertSubview:_blurView atIndex:0];
}

- (void)setupCloseButton {
    _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_closeButton setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    _closeButton.tintColor = self.currentThemeStyle[@"secondaryText"];
    _closeButton.frame = CGRectMake(_headerDragView.bounds.size.width - kHeaderHeight, 0, kHeaderHeight, kHeaderHeight);
    _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [_closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [_headerDragView addSubview:_closeButton];
}

- (void)setupCreditsLabel {
    _creditsLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, _headerDragView.bounds.size.width - kHeaderHeight - 15 - 15, kHeaderHeight)];
    _creditsLabel.text = kSettingsViewMadeByTextDefault;
    _creditsLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    _creditsLabel.textColor = [self.currentThemeStyle[@"secondaryText"] colorWithAlphaComponent:0.8];
    _creditsLabel.textAlignment = NSTextAlignmentLeft; _creditsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_headerDragView addSubview:_creditsLabel];
}

- (void)setupTabControl {
    _tabControl = [[UISegmentedControl alloc] init];
    CGFloat tabControlY = kHeaderHeight + 10;
    _tabControl.frame = CGRectMake(16, tabControlY, _containerView.bounds.size.width - 32, 36);
    _tabControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIColor *primaryAccent = self.currentThemeStyle[@"primaryAccent"];
    UIColor *secondaryText = self.currentThemeStyle[@"secondaryText"];
    if (@available(iOS 13.0, *)) {
        _tabControl.selectedSegmentTintColor = primaryAccent;
        [_tabControl setTitleTextAttributes:@{NSForegroundColorAttributeName: secondaryText} forState:UIControlStateNormal];
        [_tabControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [self contrastingColorForBackgroundColor:primaryAccent]} forState:UIControlStateSelected];
    } else {
        _tabControl.tintColor = primaryAccent;
    }
    [_tabControl addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    [_containerView addSubview:_tabControl];
}

- (void)setupScrollView {
    CGFloat scrollViewY = kHeaderHeight + 10 + 36 + 10;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, scrollViewY, _containerView.bounds.size.width, _containerView.bounds.size.height - scrollViewY)];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.backgroundColor = [UIColor clearColor]; _scrollView.showsVerticalScrollIndicator = YES;
    [_containerView addSubview:_scrollView];
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _scrollView.bounds.size.width, 10)];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth; _contentView.backgroundColor = [UIColor clearColor];
    [_scrollView addSubview:_contentView];
}

- (void)setupGestures {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOutside:)];
    tap.delegate = self; [self addGestureRecognizer:tap];
}

- (UIWindow *)activeWindow {
    UIWindow *keyWindow = nil;
    if (@available(iOS 15.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) { if (window.isKeyWindow) { keyWindow = window; break; } }
            } if (keyWindow) break;
        }
    } else if (@available(iOS 13.0, *)) {
        for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                 for (UIWindow *window in windowScene.windows) { if (window.isKeyWindow) { keyWindow = window; break; } }
            } if (keyWindow) break;
        }
    }
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    return keyWindow;
}

- (void)setupCustomGestureToShow {
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(show)];
    swipe.direction = UISwipeGestureRecognizerDirectionDown; swipe.numberOfTouchesRequired = 3;
    UIWindow *keyWindow = [self activeWindow];
    [keyWindow addGestureRecognizer:swipe];
}

- (void)addTabWithTitle:(NSString *)title {
    MenuTab *tab = [[MenuTab alloc] init]; tab.title = title; [self.tabs addObject:tab];
    [self.tabControl insertSegmentWithTitle:title atIndex:self.tabs.count-1 animated:NO];
    if (self.tabs.count == 1) {
        self.tabControl.selectedSegmentIndex = 0;
        [self reloadTabContent];
    }
}

- (void)addComponent:(MenuComponent *)component toTab:(NSUInteger)tabIndex {
    if (tabIndex >= self.tabs.count) return;
    component.delegate = self; MenuTab *tab = self.tabs[tabIndex]; [tab.components addObject:component];
    if (self.selectedTabIndex == tabIndex) {
        [self reloadTabContent];
    }
}

- (void)reloadTabContent {
    for (UIView *view in self.componentViews) { [view removeFromSuperview]; }
    [self.componentViews removeAllObjects];
    if (self.selectedTabIndex >= self.tabs.count) return;
    MenuTab *currentTab = self.tabs[self.selectedTabIndex];
    CGFloat currentY = 16.0f; CGFloat contentWidth = self.contentView.frame.size.width;
    for (MenuComponent *comp in currentTab.components) {
        UIView *componentView = [self viewForComponent:comp]; if (!componentView) continue;
        CGFloat componentHeight = kDefaultComponentHeight;
        if (comp.type == MenuComponentTypeSlider) componentHeight = 80;
        else if (comp.type == MenuComponentTypeSliderWithSwitch) componentHeight = 120;
        else if (comp.type == MenuComponentTypeLabel) {
            UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, contentWidth - 32, CGFLOAT_MAX)];
            tempLabel.font = [UIFont systemFontOfSize:comp.labelFontSize weight:comp.labelFontWeight];
            tempLabel.text = comp.title; tempLabel.numberOfLines = 0; [tempLabel sizeToFit];
            componentHeight = MAX(kDefaultComponentHeight / 2, tempLabel.frame.size.height + 10);
        }
        componentView.frame = CGRectMake(16, currentY, contentWidth - 32, componentHeight);
        [self.contentView addSubview:componentView]; [self.componentViews addObject:componentView];
        currentY += componentHeight + 16.0f;
    }
    self.contentView.frame = CGRectMake(0, 0, contentWidth, MAX(currentY, _scrollView.bounds.size.height + 1));
    self.scrollView.contentSize = CGSizeMake(contentWidth, currentY);
    [self setNeedsLayout];
}

- (UIView *)viewForComponent:(MenuComponent *)comp {
    switch (comp.type) {
        case MenuComponentTypeSlider: return [self createSliderViewForComponent:comp];
        case MenuComponentTypeSwitch: return [self createSwitchViewForComponent:comp];
        case MenuComponentTypeSliderWithSwitch: return [self createSliderWithSwitchViewForComponent:comp];
        case MenuComponentTypeLabel: return [self createLabelViewForComponent:comp];
        case MenuComponentTypeDropdown: case MenuComponentTypeThemeSelector: return [self createDropdownViewForComponent:comp];
        default: return nil;
    }
}

- (UIView *)createSliderViewForComponent:(MenuComponent *)comp {
    UIView *rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 80)];
    UILabel *titleLabel = [self createTitleLabelWithText:comp.title]; [rootView addSubview:titleLabel];
    UIView *sliderContainer = [[UIView alloc] init];
    sliderContainer.backgroundColor = self.currentThemeStyle[@"textFieldBackground"];
    sliderContainer.layer.cornerRadius = 8.0; [rootView addSubview:sliderContainer];
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = comp.minValue; slider.maximumValue = comp.maxValue; slider.value = comp.currentValue;
    slider.minimumTrackTintColor = self.currentThemeStyle[@"sliderTrack"];
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    objc_setAssociatedObject(slider, kMenuComponentAssociatedKey, comp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [sliderContainer addSubview:slider];
    UITextField *valueField = [self createValueTextFieldWithValue:comp.currentValue];
    valueField.backgroundColor = [sliderContainer.backgroundColor colorWithAlphaComponent:0.85];
    objc_setAssociatedObject(valueField, kSliderAssociatedKey, slider, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(valueField, kMenuComponentAssociatedKey, comp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [sliderContainer addSubview:valueField]; return rootView;
}

- (UIView *)createSwitchViewForComponent:(MenuComponent *)comp {
    UIView *rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, kDefaultComponentHeight)];
    UILabel *titleLabel = [self createTitleLabelWithText:comp.title]; [rootView addSubview:titleLabel];
    UISwitch *sw = [[UISwitch alloc] init]; sw.on = comp.switchValue;
    sw.onTintColor = self.currentThemeStyle[@"switchOnTint"];
    [sw addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    objc_setAssociatedObject(sw, kMenuComponentAssociatedKey, comp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [rootView addSubview:sw]; return rootView;
}

- (UIView *)createSliderWithSwitchViewForComponent:(MenuComponent *)comp {
    UIView *rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 120)];
    UIView *switchHolder = [[UIView alloc] init];
    UILabel *titleLabel = [self createTitleLabelWithText:comp.title]; [switchHolder addSubview:titleLabel];
    UISwitch *sw = [[UISwitch alloc] init]; sw.on = comp.switchValue; sw.onTintColor = self.currentThemeStyle[@"switchOnTint"];
    [sw addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    objc_setAssociatedObject(sw, kMenuComponentAssociatedKey, comp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [switchHolder addSubview:sw]; [rootView addSubview:switchHolder];
    UIView *sliderContainer = [[UIView alloc] init];
    sliderContainer.backgroundColor = self.currentThemeStyle[@"textFieldBackground"];
    sliderContainer.layer.cornerRadius = 8.0; sliderContainer.alpha = comp.switchValue ? 1.0 : 0.5;
    objc_setAssociatedObject(sw, kComponentViewAssociatedKey, sliderContainer, OBJC_ASSOCIATION_ASSIGN);
    [rootView addSubview:sliderContainer];
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumValue = comp.minValue; slider.maximumValue = comp.maxValue; slider.value = comp.currentValue;
    slider.minimumTrackTintColor = self.currentThemeStyle[@"sliderTrack"]; slider.enabled = comp.switchValue;
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    objc_setAssociatedObject(slider, kMenuComponentAssociatedKey, comp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [sliderContainer addSubview:slider];
    UITextField *valueField = [self createValueTextFieldWithValue:comp.currentValue];
    valueField.backgroundColor = [sliderContainer.backgroundColor colorWithAlphaComponent:0.85];
    valueField.enabled = comp.switchValue;
    objc_setAssociatedObject(valueField, kSliderAssociatedKey, slider, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(valueField, kMenuComponentAssociatedKey, comp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [sliderContainer addSubview:valueField]; return rootView;
}

- (UIView *)createLabelViewForComponent:(MenuComponent *)comp {
    UIView *rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, kDefaultComponentHeight)];
    UILabel *label = [[UILabel alloc] init]; label.text = comp.title;
    label.font = [UIFont systemFontOfSize:comp.labelFontSize weight:comp.labelFontWeight];
    label.textColor = self.currentThemeStyle[@"secondaryText"];
    label.textAlignment = comp.labelAlignment; label.numberOfLines = 0;
    [rootView addSubview:label]; return rootView;
}

- (UIView *)createDropdownViewForComponent:(MenuComponent *)comp {
    UIView *rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, kDefaultComponentHeight)];
    UILabel *titleLabel = [self createTitleLabelWithText:comp.title]; [rootView addSubview:titleLabel];
    UIButton *dropdownButton = [UIButton buttonWithType:UIButtonTypeSystem];
    dropdownButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    NSString *currentSelection = (comp.selectedIndex >= 0 && comp.selectedIndex < comp.options.count) ? comp.options[comp.selectedIndex] : @"Chọn...";
    [dropdownButton setTitle:currentSelection forState:UIControlStateNormal];
    dropdownButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    [dropdownButton setTitleColor:self.currentThemeStyle[@"buttonText"] forState:UIControlStateNormal];
    dropdownButton.layer.borderColor = [self.currentThemeStyle[@"primaryAccent"] CGColor];
    dropdownButton.layer.borderWidth = 1.0; dropdownButton.layer.cornerRadius = 6.0;
    dropdownButton.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    [dropdownButton addTarget:self action:@selector(dropdownButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    objc_setAssociatedObject(dropdownButton, kMenuComponentAssociatedKey, comp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [rootView addSubview:dropdownButton]; return rootView;
}

- (UILabel *)createTitleLabelWithText:(NSString *)text {
    UILabel *titleLabel = [[UILabel alloc] init]; titleLabel.text = text;
    titleLabel.textColor = self.currentThemeStyle[@"secondaryText"];
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    return titleLabel;
}

- (UITextField *)createValueTextFieldWithValue:(CGFloat)value {
    UITextField *valueField = [[UITextField alloc] init];
    valueField.layer.cornerRadius = 6.0; valueField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    valueField.text = [NSString stringWithFormat:@"%.2f", value];
    valueField.textColor = self.currentThemeStyle[@"secondaryText"];
    valueField.textAlignment = NSTextAlignmentCenter;
    valueField.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [valueField addTarget:self action:@selector(sliderTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [valueField addTarget:self action:@selector(sliderTextFieldEditingDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
    return valueField;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat screenWidth = self.bounds.size.width; CGFloat screenHeight = self.bounds.size.height;
    CGFloat newContainerWidth = MIN(screenWidth * 0.9, 400); CGFloat newContainerHeight = MIN(screenHeight * 0.8, 700);
    BOOL containerSizeChanged = (_containerView.frame.size.width != newContainerWidth || _containerView.frame.size.height != newContainerHeight);
    if (containerSizeChanged) { _containerView.frame = CGRectMake(0, 0, newContainerWidth, newContainerHeight); }
    if (self.hasBeenDraggedOrInitiallyPositioned && !CGPointEqualToPoint(self.lastKnownContainerCenter, CGPointZero)) {
        CGPoint targetCenter = self.lastKnownContainerCenter;
        if (containerSizeChanged) {
            targetCenter.x = MIN(MAX(targetCenter.x, newContainerWidth / 2), screenWidth - newContainerWidth / 2);
            targetCenter.y = MIN(MAX(targetCenter.y, newContainerHeight / 2), screenHeight - newContainerHeight / 2);
        }
        _containerView.center = targetCenter;
    } else { _containerView.center = CGPointMake(screenWidth / 2, screenHeight / 2); }
    self.lastKnownContainerCenter = _containerView.center;

    _headerDragView.frame = CGRectMake(0, 0, _containerView.bounds.size.width, kHeaderHeight);
    _closeButton.frame = CGRectMake(_headerDragView.bounds.size.width - kHeaderHeight, 0, kHeaderHeight, kHeaderHeight);
    _creditsLabel.frame = CGRectMake(15, 0, _headerDragView.bounds.size.width - kHeaderHeight - 15 - 15, kHeaderHeight);
    CGFloat tabControlY = kHeaderHeight + 10;
    _tabControl.frame = CGRectMake(16, tabControlY, _containerView.bounds.size.width - 32, 36);
    CGFloat scrollViewY = tabControlY + 36 + 10;
    _scrollView.frame = CGRectMake(0, scrollViewY, _containerView.bounds.size.width, _containerView.bounds.size.height - scrollViewY);
    CGFloat contentWidth = _scrollView.bounds.size.width;
    if (_contentView.frame.size.width != contentWidth) {
        CGRect contentViewFrame = _contentView.frame; contentViewFrame.size.width = contentWidth; _contentView.frame = contentViewFrame;
    }
    CGFloat usableWidth = contentWidth - 32;

    for (UIView *componentRootView in self.componentViews) {
        CGRect rootFrame = componentRootView.frame; rootFrame.size.width = usableWidth;
        componentRootView.frame = rootFrame;
        MenuComponent *comp = nil;
        for(UIView *sub in componentRootView.subviews){
            comp = objc_getAssociatedObject(sub, kMenuComponentAssociatedKey); if(comp) break;
            for(UIView *deepSub in sub.subviews){ comp = objc_getAssociatedObject(deepSub, kMenuComponentAssociatedKey); if(comp) break; } if(comp) break;
        }
        if (!comp && componentRootView.subviews.count == 1 && [componentRootView.subviews.firstObject isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)componentRootView.subviews.firstObject;
            label.frame = componentRootView.bounds; continue;
        }
        if (!comp) continue;

        if (comp.type == MenuComponentTypeSwitch) {
            UILabel *titleL = nil; UISwitch *sw = nil;
            for(UIView *v in componentRootView.subviews) { if([v isKindOfClass:[UILabel class]]) titleL = (UILabel*)v; if([v isKindOfClass:[UISwitch class]]) sw = (UISwitch*)v; }
            if(titleL && sw){
                CGFloat swWidth = sw.intrinsicContentSize.width;
                titleL.frame = CGRectMake(0, 0, usableWidth - swWidth - 8, componentRootView.bounds.size.height);
                sw.center = CGPointMake(usableWidth - swWidth / 2, componentRootView.bounds.size.height / 2);
            }
        } else if (comp.type == MenuComponentTypeSlider) {
            UILabel *titleL = nil; UIView *sliderCont = nil;
            for(UIView *v in componentRootView.subviews) { if([v isKindOfClass:[UILabel class]]) titleL = (UILabel*)v; else if (v.subviews.count > 0) sliderCont = v; }
            if(titleL && sliderCont){
                titleL.frame = CGRectMake(0, 0, usableWidth, 20);
                sliderCont.frame = CGRectMake(0, 20 + 8, usableWidth, 44);
                UISlider* s = nil; UITextField* t = nil;
                for(UIView* el in sliderCont.subviews){ if([el isKindOfClass:[UISlider class]]) s = (UISlider*)el; if([el isKindOfClass:[UITextField class]]) t = (UITextField*)el; }
                if(s && t){
                    t.frame = CGRectMake(sliderCont.bounds.size.width - kSliderTextFieldWidth - 8, (sliderCont.bounds.size.height - 28)/2, kSliderTextFieldWidth, 28);
                    s.frame = CGRectMake(12, (sliderCont.bounds.size.height - s.intrinsicContentSize.height)/2, t.frame.origin.x - 12 - 8, s.intrinsicContentSize.height);
                }
            }
        } else if (comp.type == MenuComponentTypeSliderWithSwitch) {
            UIView *swHolder = componentRootView.subviews.count > 0 ? componentRootView.subviews[0] : nil;
            UIView *slHolder = componentRootView.subviews.count > 1 ? componentRootView.subviews[1] : nil;
            if(swHolder && slHolder){
                swHolder.frame = CGRectMake(0, 0, usableWidth, 44);
                UILabel* titleL_sws = nil; UISwitch* sw_sws = nil;
                for(UIView* el in swHolder.subviews){ if([el isKindOfClass:[UILabel class]]) titleL_sws = (UILabel*)el; if([el isKindOfClass:[UISwitch class]]) sw_sws = (UISwitch*)el; }
                if(titleL_sws && sw_sws){
                    CGFloat swWidth_sws = sw_sws.intrinsicContentSize.width;
                    titleL_sws.frame = CGRectMake(0, 0, usableWidth - swWidth_sws - 8, swHolder.bounds.size.height);
                    sw_sws.center = CGPointMake(usableWidth - swWidth_sws / 2, swHolder.bounds.size.height / 2);
                }
                slHolder.frame = CGRectMake(0, 44 + 4, usableWidth, 68);
                UISlider* s_sws = nil; UITextField* t_sws = nil;
                for(UIView* el in slHolder.subviews){ if([el isKindOfClass:[UISlider class]]) s_sws = (UISlider*)el; if([el isKindOfClass:[UITextField class]]) t_sws = (UITextField*)el; }
                if(s_sws && t_sws){
                    t_sws.frame = CGRectMake(slHolder.bounds.size.width - kSliderTextFieldWidth - 8, (slHolder.bounds.size.height - 28)/2, kSliderTextFieldWidth, 28);
                    s_sws.frame = CGRectMake(12, (slHolder.bounds.size.height - s_sws.intrinsicContentSize.height)/2, t_sws.frame.origin.x - 12 - 8, s_sws.intrinsicContentSize.height);
                }
            }
        } else if (comp.type == MenuComponentTypeLabel) {
             UILabel *label = nil;
             if (componentRootView.subviews.count == 1 && [componentRootView.subviews.firstObject isKindOfClass:[UILabel class]]) {
                 label = (UILabel *)componentRootView.subviews.firstObject;
                 label.frame = componentRootView.bounds;
             }
        } else if (comp.type == MenuComponentTypeDropdown || comp.type == MenuComponentTypeThemeSelector) {
            UILabel *titleL = nil; UIButton *btn = nil;
            for(UIView *v in componentRootView.subviews) { if([v isKindOfClass:[UILabel class]]) titleL = (UILabel*)v; if([v isKindOfClass:[UIButton class]]) btn = (UIButton*)v; }
            if(titleL && btn){
                CGFloat btnWidth = 130;
                titleL.frame = CGRectMake(0, 0, usableWidth - btnWidth - 8, componentRootView.bounds.size.height);
                btn.frame = CGRectMake(usableWidth - btnWidth, (componentRootView.bounds.size.height - 34)/2, btnWidth, 34);
            }
        }
    }
}

- (void)sliderValueChanged:(UISlider *)sender {
    MenuComponent *comp = objc_getAssociatedObject(sender, kMenuComponentAssociatedKey); if (!comp) return;
    CGFloat newValue = roundf(sender.value * 100) / 100; sender.value = newValue; comp.currentValue = newValue;
    UIView *sliderContainerView = sender.superview;
    for (UIView *subview in sliderContainerView.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            ((UITextField *)subview).text = [NSString stringWithFormat:@"%.2f", newValue]; break;
        }
    }
    [self sliderValueChangedFromComponent:newValue forKey:comp.key component:comp];
    if (self.delegate && [self.delegate respondsToSelector:@selector(sliderValueChanged:forKey:)]) {
        [self.delegate sliderValueChanged:newValue forKey:comp.key];
    }
}

- (void)sliderTextFieldChanged:(UITextField *)sender {
    if ([sender.text containsString:@","]) {
        sender.text = [sender.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    }
}

- (void)sliderTextFieldEditingDidEnd:(UITextField *)sender {
    MenuComponent *comp = objc_getAssociatedObject(sender, kMenuComponentAssociatedKey);
    UISlider *slider = objc_getAssociatedObject(sender, kSliderAssociatedKey); if (!comp || !slider) return;
    NSString *processedText = [sender.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    CGFloat value = [processedText floatValue];
    CGFloat clampedValue = MAX(slider.minimumValue, MIN(slider.maximumValue, value));
    clampedValue = roundf(clampedValue * 100) / 100;
    sender.text = [NSString stringWithFormat:@"%.2f", clampedValue];
    BOOL sliderNeedsUpdate = (fabs(slider.value - clampedValue) > 0.001);
    comp.currentValue = clampedValue;
    if (sliderNeedsUpdate) {
        [slider setValue:clampedValue animated:YES];
    } else {
        [self sliderValueChangedFromComponent:clampedValue forKey:comp.key component:comp];
        if (self.delegate && [self.delegate respondsToSelector:@selector(sliderValueChanged:forKey:)]) {
            [self.delegate sliderValueChanged:clampedValue forKey:comp.key];
        }
    }
}

- (void)switchValueChanged:(UISwitch *)sender {
    MenuComponent *comp = objc_getAssociatedObject(sender, kMenuComponentAssociatedKey); if (!comp) return;
    comp.switchValue = sender.on;
    if (comp.type == MenuComponentTypeSliderWithSwitch) {
        UIView *sliderContainer = objc_getAssociatedObject(sender, kComponentViewAssociatedKey);
        if (sliderContainer) {
            [UIView animateWithDuration:0.2 animations:^{ sliderContainer.alpha = sender.on ? 1.0 : 0.5; }];
            for (UIView *subview in sliderContainer.subviews) {
                if ([subview isKindOfClass:[UISlider class]] || [subview isKindOfClass:[UITextField class]]) {
                    if ([subview respondsToSelector:@selector(setEnabled:)]) { [(UIControl *)subview setEnabled:sender.on]; }
                }
            }
        }
    }
    [self switchValueChangedFromComponent:sender.on forKey:comp.key component:comp];
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchValueChanged:forKey:)]) {
        [self.delegate switchValueChanged:sender.on forKey:comp.key];
    }
}

- (void)dropdownButtonTapped:(UIButton *)sender {
    MenuComponent *comp = objc_getAssociatedObject(sender, kMenuComponentAssociatedKey);
    if (!comp || !(comp.type == MenuComponentTypeDropdown || comp.type == MenuComponentTypeThemeSelector)) return;
    [self dismissActivePickerView]; self.activeDropdownComponent = comp;
    CGFloat pickerHeight = 216.0; CGFloat toolbarHeight = 44.0; CGFloat containerHeight = pickerHeight + toolbarHeight;
    self.pickerContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height, self.bounds.size.width, containerHeight)];
    self.pickerContainerView.backgroundColor = self.currentThemeStyle[@"viewBackgroundAlpha"] ?: [UIColor secondarySystemBackgroundColor];
    self.pickerContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.pickerContainerView.layer.shadowOffset = CGSizeMake(0, -2); self.pickerContainerView.layer.shadowOpacity = 0.1; self.pickerContainerView.layer.shadowRadius = 4.0;
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, toolbarHeight)];
    toolbar.barStyle = ([self.currentThemeStyle[@"blurStyle"] integerValue] == UIBlurEffectStyleDark || [self.currentThemeStyle[@"blurStyle"] integerValue] == UIBlurEffectStyleSystemMaterialDark) ? UIBarStyleBlack : UIBarStyleDefault;
    toolbar.tintColor = self.currentThemeStyle[@"primaryAccent"];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Xong" style:UIBarButtonItemStyleDone target:self action:@selector(pickerDoneButtonTapped)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolbar setItems:@[flexibleSpace, doneButton]]; [self.pickerContainerView addSubview:toolbar];
    self.activePickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, toolbarHeight, self.bounds.size.width, pickerHeight)];
    self.activePickerView.delegate = self; self.activePickerView.dataSource = self;
    [self.activePickerView selectRow:comp.selectedIndex inComponent:0 animated:NO];
    [self.pickerContainerView addSubview:self.activePickerView]; [self addSubview:self.pickerContainerView];
    [UIView animateWithDuration:0.3 animations:^{
        self.pickerContainerView.frame = CGRectMake(0, self.bounds.size.height - containerHeight, self.bounds.size.width, containerHeight);
    }];
}

- (void)pickerDoneButtonTapped {
    if (self.activeDropdownComponent && self.activePickerView) {
        NSInteger selectedRow = [self.activePickerView selectedRowInComponent:0];
        self.activeDropdownComponent.selectedIndex = selectedRow;
        NSString *selectedValue = (selectedRow >= 0 && selectedRow < self.activeDropdownComponent.options.count) ? self.activeDropdownComponent.options[selectedRow] : nil;
        for (UIView *rootCompView in self.componentViews) {
            for(UIView *subview in rootCompView.subviews){
                if([subview isKindOfClass:[UIButton class]]){
                    MenuComponent* btnComp = objc_getAssociatedObject(subview, kMenuComponentAssociatedKey);
                    if(btnComp == self.activeDropdownComponent){
                        [(UIButton*)subview setTitle:selectedValue forState:UIControlStateNormal]; break;
                    }
                }
            }
        }
        if (self.activeDropdownComponent.type == MenuComponentTypeThemeSelector) {
            [[NSUserDefaults standardUserDefaults] setInteger:selectedRow forKey:kSettingsViewSelectedThemeKey];
            [self applyTheme:(ThemeIdentifier)selectedRow];
        } else if (self.activeDropdownComponent.type == MenuComponentTypeDropdown) {
            if (self.activeDropdownComponent.key) {
                [[NSUserDefaults standardUserDefaults] setInteger:selectedRow forKey:self.activeDropdownComponent.key];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(dropdownValueChanged:value:forKey:)]) {
                [self.delegate dropdownValueChanged:selectedRow value:selectedValue forKey:self.activeDropdownComponent.key];
            }
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [self dismissActivePickerView];
}

- (void)dismissActivePickerView {
    if (self.pickerContainerView) {
        [UIView animateWithDuration:0.3 animations:^{
            self.pickerContainerView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.pickerContainerView.frame.size.height);
        } completion:^(BOOL finished) {
            [self.pickerContainerView removeFromSuperview]; self.pickerContainerView = nil;
            self.activePickerView = nil; self.activeDropdownComponent = nil;
        }];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.activeDropdownComponent ? self.activeDropdownComponent.options.count : 0;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view {
    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.font = [UIFont systemFontOfSize:18];
        pickerLabel.textAlignment = NSTextAlignmentCenter;
    }
    pickerLabel.text = (self.activeDropdownComponent && row < self.activeDropdownComponent.options.count) ? self.activeDropdownComponent.options[row] : @"";
    pickerLabel.textColor = self.currentThemeStyle[@"secondaryText"] ?: [UIColor blackColor];
    return pickerLabel;
}

- (void)tabChanged:(UISegmentedControl *)sender {
    if (self.selectedTabIndex == sender.selectedSegmentIndex) return;
    self.selectedTabIndex = sender.selectedSegmentIndex; [self reloadTabContent];
}

- (void)show {
    UIWindow *window = [self activeWindow];
    if (!window) return;
    if (!self.superview) {
        self.frame = window.bounds;
        [window addSubview:self];
    } else {
        [self.superview bringSubviewToFront:self];
    }

    if (self.hasBeenDraggedOrInitiallyPositioned && !CGPointEqualToPoint(self.lastKnownContainerCenter, CGPointZero)) {
        CGFloat cW = _containerView.bounds.size.width;
        CGFloat cH = _containerView.bounds.size.height;
        _containerView.center = CGPointMake( MAX(cW/2, MIN(self.bounds.size.width - cW/2, self.lastKnownContainerCenter.x)), MAX(cH/2, MIN(self.bounds.size.height - cH/2, self.lastKnownContainerCenter.y)) );
    } else {
        _containerView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    }
    self.lastKnownContainerCenter = _containerView.center;
    self.alpha = 0; _containerView.transform = CGAffineTransformMakeScale(0.9, 0.9); _containerView.alpha = 0.5;
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 1; self->_containerView.transform = CGAffineTransformIdentity; self->_containerView.alpha = 1.0;
    } completion:nil];
}

- (void)hide {
    self.lastKnownContainerCenter = self.containerView.center; self.hasBeenDraggedOrInitiallyPositioned = YES;
    [self dismissActivePickerView];
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0; self->_containerView.transform = CGAffineTransformMakeScale(0.9, 0.9); self->_containerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) { [self removeFromSuperview];
            self->_containerView.transform = CGAffineTransformIdentity; self->_containerView.alpha = 1.0; }
    }];
}

- (void)panContainer:(UIPanGestureRecognizer *)pan {
    UIView *targetView = self.containerView; CGPoint translation = [pan translationInView:self];
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(self.lastKnownContainerCenter.x + translation.x, self.lastKnownContainerCenter.y + translation.y);
        CGFloat cW = targetView.bounds.size.width; CGFloat cH = targetView.bounds.size.height;
        CGFloat pW = self.bounds.size.width; CGFloat pH = self.bounds.size.height;
        newCenter.x = MAX(cW/2, MIN(pW - cW/2, newCenter.x)); newCenter.y = MAX(cH/2, MIN(pH - cH/2, newCenter.y));
        targetView.center = newCenter;
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        self.lastKnownContainerCenter = targetView.center; self.hasBeenDraggedOrInitiallyPositioned = YES;
    }
}

- (void)handleTapOutside:(UITapGestureRecognizer *)tap {
    CGPoint location = [tap locationInView:self];
    if (self.pickerContainerView && CGRectContainsPoint(self.pickerContainerView.frame, location)) { return; }
    if (!CGRectContainsPoint(self.containerView.frame, location)) { [self hide]; }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.pickerContainerView && CGRectContainsPoint(self.pickerContainerView.frame, [touch locationInView:self])) { return NO; }
    if (gestureRecognizer == self.gestureRecognizers.lastObject && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) { return touch.view == self; }
    return YES;
}

- (void)switchValueChangedFromComponent:(BOOL)on forKey:(NSString *)key component:(MenuComponent *)component {
    if (component.key) {
        [[NSUserDefaults standardUserDefaults] setBool:on forKey:component.key];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)sliderValueChangedFromComponent:(CGFloat)value forKey:(NSString *)key component:(MenuComponent *)component {
    NSString *userDefaultsKey = nil;
    if (component.type == MenuComponentTypeSliderWithSwitch) {
        userDefaultsKey = component.key ? [NSString stringWithFormat:@"%@_SliderValue", component.key] : nil;
    } else {
        userDefaultsKey = component.key;
    }
    if (userDefaultsKey) {
        [[NSUserDefaults standardUserDefaults] setFloat:value forKey:userDefaultsKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)switchValueChanged:(BOOL)on forKey:(NSString *)key {
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchValueChanged:forKey:)]) { [self.delegate switchValueChanged:on forKey:key]; }
}

- (void)sliderValueChanged:(CGFloat)value forKey:(NSString *)key {
    if (self.delegate && [self.delegate respondsToSelector:@selector(sliderValueChanged:forKey:)]) { [self.delegate sliderValueChanged:value forKey:key]; }
}

- (void)dropdownValueChanged:(NSInteger)selectedIndex value:(NSString *)selectedValue forKey:(NSString *)key {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dropdownValueChanged:value:forKey:)]) { [self.delegate dropdownValueChanged:selectedIndex value:selectedValue forKey:key]; }
}

- (MenuComponent * _Nullable)findComponentForKey:(NSString *)key {
    if (!key) return nil;
    for (MenuTab *tab in self.tabs) {
        for (MenuComponent *comp in tab.components) {
            if (comp.key && [comp.key isEqualToString:key]) { return comp; }
            if (comp.type == MenuComponentTypeSliderWithSwitch) {
                NSString *sliderValueKey = comp.key ? [NSString stringWithFormat:@"%@_SliderValue", comp.key] : nil;
                if (sliderValueKey && [sliderValueKey isEqualToString:key]) return comp;
            }
        }
    } return nil;
}

- (BOOL)boolValueForKey:(NSString *)key {
    MenuComponent *comp = [self findComponentForKey:key];
    if (comp && (comp.type == MenuComponentTypeSwitch || comp.type == MenuComponentTypeSliderWithSwitch)) { return comp.switchValue; }
    return key ? [[NSUserDefaults standardUserDefaults] boolForKey:key] : NO;
}

- (CGFloat)floatValueForKey:(NSString *)key {
    MenuComponent *comp = [self findComponentForKey:key];
    if (comp) {
        if (comp.type == MenuComponentTypeSlider) { return comp.currentValue; }
        if (comp.type == MenuComponentTypeSliderWithSwitch) {
            NSString *sliderValueKey = comp.key ? [NSString stringWithFormat:@"%@_SliderValue", comp.key] : nil;
            if (sliderValueKey && [sliderValueKey isEqualToString:key]) { return comp.currentValue; }
            if (comp.key && [comp.key isEqualToString:key]) { return comp.currentValue; }
        }
    }
    return key ? [[NSUserDefaults standardUserDefaults] floatForKey:key] : 0.0f;
}

- (NSInteger)integerValueForKey:(NSString *)key {
    MenuComponent *comp = [self findComponentForKey:key];
    if (comp && (comp.type == MenuComponentTypeDropdown || comp.type == MenuComponentTypeThemeSelector)) { return comp.selectedIndex; }
    return key ? [[NSUserDefaults standardUserDefaults] integerForKey:key] : -1;
}

- (NSString * _Nullable)stringValueForKey:(NSString *)key {
    MenuComponent *comp = [self findComponentForKey:key];
    if (comp && (comp.type == MenuComponentTypeDropdown || comp.type == MenuComponentTypeThemeSelector)) {
        if (comp.selectedIndex >= 0 && comp.selectedIndex < comp.options.count) { return comp.options[comp.selectedIndex]; }
    }
    return key ? [[NSUserDefaults standardUserDefaults] stringForKey:key] : nil;
}
@end