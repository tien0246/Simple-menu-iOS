#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ESPShapeType) {
    ESPShapeTypeLine,
    ESPShapeTypeRect,
    ESPShapeTypeCircle,
    ESPShapeTypeDot,
    ESPShapeTypeText
};

@interface ESPShape : NSObject
@property (nonatomic, assign) ESPShapeType type;
@property (nonatomic, assign) CGPoint  p1;
@property (nonatomic, assign) CGPoint  p2;
@property (nonatomic, strong) UIColor *stroke;
@property (nonatomic, strong) UIColor *fill;
@property (nonatomic, assign) CGFloat  lineWidth;
@property (nonatomic, copy)   NSString *text;
@property (nonatomic, strong) UIFont   *font;
@property (nonatomic, strong) UIColor  *textColor;
@property (nonatomic, assign) NSTextAlignment textAlignment;
@property (nonatomic, assign) UIFontWeight fontWeight;
@end

@interface ESPView : UIView
+ (instancetype)shared;
- (void)addLineFrom:(CGPoint)start to:(CGPoint)end color:(UIColor *)color lineWidth:(CGFloat)width;
- (void)addRect:(CGRect)rect color:(UIColor *)stroke lineWidth:(CGFloat)width fillColor:(UIColor *)fill;
- (void)addCircleAt:(CGPoint)center radius:(CGFloat)radius color:(UIColor *)stroke lineWidth:(CGFloat)width fillColor:(UIColor *)fill;
- (void)addDotAt:(CGPoint)center radius:(CGFloat)radius color:(UIColor *)color;
- (void)addText:(NSString *)text at:(CGPoint)origin color:(UIColor *)color fontSize:(CGFloat)fontSize alignment:(NSTextAlignment)alignment fontWeight:(UIFontWeight)weight;
- (void)clearShapes;
@end
