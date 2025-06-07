// SettingsView.h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define kSettingsViewMadeByTextDefault @"Made by Doan Tien"

typedef NS_ENUM(NSInteger, MenuComponentType) {
    MenuComponentTypeUnknown,
    MenuComponentTypeSlider,
    MenuComponentTypeSwitch,
    MenuComponentTypeSliderWithSwitch,
    MenuComponentTypeLabel,
    MenuComponentTypeDropdown,
    MenuComponentTypeThemeSelector
};

typedef NS_ENUM(NSInteger, ThemeIdentifier) {
    ThemeIdentifierDefault,
    ThemeIdentifierBlue,
    ThemeIdentifierPink
};

@protocol MenuComponentDelegate <NSObject>
@optional
- (void)switchValueChanged:(BOOL)on forKey:(NSString *)key;
- (void)sliderValueChanged:(CGFloat)value forKey:(NSString *)key;
- (void)dropdownValueChanged:(NSInteger)selectedIndex value:(NSString *)selectedValue forKey:(NSString *)key;
- (void)themeChanged:(ThemeIdentifier)themeIdentifier;
@end

@interface MenuComponent : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong, nullable) NSString *key;
@property (nonatomic, assign) MenuComponentType type;
@property (nonatomic, weak, nullable) id<MenuComponentDelegate> delegate;
@property (nonatomic, assign) CGFloat minValue;
@property (nonatomic, assign) CGFloat maxValue;
@property (nonatomic, assign) CGFloat currentValue;
@property (nonatomic, assign) BOOL switchValue;
@property (nonatomic, assign) CGFloat labelFontSize;
@property (nonatomic, assign) NSTextAlignment labelAlignment;
@property (nonatomic, assign) UIFontWeight labelFontWeight;
@property (nonatomic, strong, nullable) NSArray<NSString *> *options;
@property (nonatomic, assign) NSInteger selectedIndex;

+ (instancetype)sliderComponentWithTitle:(NSString *)title key:(NSString *)key min:(CGFloat)min max:(CGFloat)max initial:(CGFloat)initial;
+ (instancetype)switchComponentWithTitle:(NSString *)title key:(NSString *)key initial:(BOOL)initial;
+ (instancetype)sliderWithSwitchComponentWithTitle:(NSString *)title key:(NSString *)key min:(CGFloat)min max:(CGFloat)max initial:(CGFloat)initial switchInitial:(BOOL)switchInitial;
+ (instancetype)labelComponentWithText:(NSString *)text;
+ (instancetype)labelComponentWithText:(NSString *)text
                              fontSize:(CGFloat)fontSize
                             alignment:(NSTextAlignment)alignment
                            fontWeight:(UIFontWeight)fontWeight;
+ (instancetype)dropdownComponentWithTitle:(NSString *)title
                                       key:(NSString *)key
                                   options:(NSArray<NSString *> *)options
                           initialSelected:(NSInteger)initialSelected;
+ (instancetype)themeSelectorComponentWithTitle:(NSString *)title
                                            key:(NSString *)key
                                initialSelected:(ThemeIdentifier)initialSelected;
@end

@interface MenuTab : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSMutableArray<MenuComponent *> *components;
@end

@interface SettingsView : UIView <MenuComponentDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, weak, nullable) id<MenuComponentDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<MenuTab *> *tabs;
@property (nonatomic, assign) NSInteger selectedTabIndex;
@property (nonatomic, strong, readonly) UIView *headerDragView;
@property (nonatomic, strong, readonly) UILabel *creditsLabel;

- (void)setCreditsText:(NSString * _Nullable)text;
+ (instancetype)shared;
- (void)show;
- (void)hide;
- (void)setupCustomGestureToShow;
- (void)addTabWithTitle:(NSString *)title;
- (void)addComponent:(MenuComponent *)component toTab:(NSUInteger)tabIndex;
- (BOOL)boolValueForKey:(NSString *)key;
- (CGFloat)floatValueForKey:(NSString *)key;
- (NSInteger)integerValueForKey:(NSString *)key;
- (NSString * _Nullable)stringValueForKey:(NSString *)key;
- (void)applyTheme:(ThemeIdentifier)themeIdentifier;
- (ThemeIdentifier)currentThemeIdentifier;
@end

NS_ASSUME_NONNULL_END
