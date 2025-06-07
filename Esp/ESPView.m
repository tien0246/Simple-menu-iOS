#import "ESPView.h"

@implementation ESPShape
- (instancetype)init {
    if (self = [super init]) {
        _stroke = UIColor.redColor;
        _lineWidth = 1.0;
        _textAlignment = NSTextAlignmentLeft;
        _fontWeight = UIFontWeightRegular;
    }
    return self;
}
@end

@interface ESPView ()
@property (nonatomic, strong) NSMutableArray<ESPShape *> *shapes;
@end

@implementation ESPView {
    NSMutableArray<ESPShape *> *_shapesInternal;
}
static ESPView *_esp_sharedInstance = nil;

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_esp_sharedInstance) {
            _esp_sharedInstance = [[ESPView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
    });
    return _esp_sharedInstance;
}

- (UIWindow *)activeWindow {
    UIWindow *key = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:UIWindowScene.class] && scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *win in ((UIWindowScene *)scene).windows) {
                    if (win.isKeyWindow) { key = win; break; }
                }
            }
            if (key) break;
        }
    }
    if (!key) key = UIApplication.sharedApplication.keyWindow;
    return key;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;
        _shapesInternal = [NSMutableArray array];
        UIWindow *w = [self activeWindow];
        if (w) {
            self.frame = w.bounds;
            self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [w addSubview:self];
        }
        _esp_sharedInstance = self;
    }
    return self;
}

- (void)addShape:(ESPShape *)shape {
    [_shapesInternal addObject:shape];
    [self setNeedsDisplay];
}

- (void)addLineFrom:(CGPoint)start to:(CGPoint)end color:(UIColor *)color lineWidth:(CGFloat)width {
    ESPShape *s = [ESPShape new];
    s.type = ESPShapeTypeLine;
    s.p1 = start;
    s.p2 = end;
    s.stroke = color;
    s.lineWidth = width;
    [self addShape:s];
}

- (void)addRect:(CGRect)rect color:(UIColor *)stroke lineWidth:(CGFloat)width fillColor:(UIColor *)fill {
    ESPShape *s = [ESPShape new];
    s.type = ESPShapeTypeRect;
    s.p1 = rect.origin;
    s.p2 = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    s.stroke = stroke;
    s.fill = fill;
    s.lineWidth = width;
    [self addShape:s];
}

- (void)addCircleAt:(CGPoint)center radius:(CGFloat)radius color:(UIColor *)stroke lineWidth:(CGFloat)width fillColor:(UIColor *)fill {
    ESPShape *s = [ESPShape new];
    s.type = ESPShapeTypeCircle;
    s.p1 = center;
    s.p2 = CGPointMake(radius, 0);
    s.stroke = stroke;
    s.fill = fill;
    s.lineWidth = width;
    [self addShape:s];
}

- (void)addDotAt:(CGPoint)center radius:(CGFloat)radius color:(UIColor *)color {
    ESPShape *s = [ESPShape new];
    s.type = ESPShapeTypeDot;
    s.p1 = center;
    s.p2 = CGPointMake(radius, 0);
    s.fill = color;
    s.stroke = color;
    s.lineWidth = 0;
    [self addShape:s];
}

- (void)addText:(NSString *)text at:(CGPoint)origin color:(UIColor *)color fontSize:(CGFloat)fontSize alignment:(NSTextAlignment)alignment fontWeight:(UIFontWeight)weight {
    if (text.length == 0) return;
    ESPShape *s = [ESPShape new];
    s.type = ESPShapeTypeText;
    s.text = text;
    s.p1 = origin;
    s.textColor = color;
    s.font = [UIFont systemFontOfSize:fontSize weight:weight];
    s.textAlignment = alignment;
    s.fontWeight = weight;
    [self addShape:s];
}

- (void)clearShapes {
    [_shapesInternal removeAllObjects];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    for (ESPShape *s in _shapesInternal) {
        switch (s.type) {
            case ESPShapeTypeLine: {
                CGContextSetLineWidth(ctx, s.lineWidth);
                CGContextSetStrokeColorWithColor(ctx, s.stroke.CGColor);
                CGContextMoveToPoint(ctx, s.p1.x, s.p1.y);
                CGContextAddLineToPoint(ctx, s.p2.x, s.p2.y);
                CGContextStrokePath(ctx);
            } break;

            case ESPShapeTypeRect: {
                CGContextSetLineWidth(ctx, s.lineWidth);
                CGContextSetStrokeColorWithColor(ctx, s.stroke.CGColor);
                CGRect r = CGRectMake(s.p1.x, s.p1.y, s.p2.x - s.p1.x, s.p2.y - s.p1.y);
                if (s.fill) {
                    CGContextSetFillColorWithColor(ctx, s.fill.CGColor);
                    CGContextAddRect(ctx, r);
                    CGContextDrawPath(ctx, kCGPathFillStroke);
                } else {
                    CGContextAddRect(ctx, r);
                    CGContextStrokePath(ctx);
                }
            } break;

            case ESPShapeTypeCircle: {
                CGContextSetLineWidth(ctx, s.lineWidth);
                CGContextSetStrokeColorWithColor(ctx, s.stroke.CGColor);
                CGFloat radius = s.p2.x;
                CGRect c = CGRectMake(s.p1.x - radius, s.p1.y - radius, radius * 2, radius * 2);
                if (s.fill) {
                    CGContextSetFillColorWithColor(ctx, s.fill.CGColor);
                    CGContextAddEllipseInRect(ctx, c);
                    CGContextDrawPath(ctx, kCGPathFillStroke);
                } else {
                    CGContextAddEllipseInRect(ctx, c);
                    CGContextStrokePath(ctx);
                }
            } break;

            case ESPShapeTypeDot: {
                CGFloat radius = s.p2.x;
                CGRect d = CGRectMake(s.p1.x - radius, s.p1.y - radius, radius * 2, radius * 2);
                CGContextSetFillColorWithColor(ctx, s.fill.CGColor);
                CGContextAddEllipseInRect(ctx, d);
                CGContextFillPath(ctx);
            } break;

            case ESPShapeTypeText: {
                UIFont *font = s.font ?: [UIFont systemFontOfSize:14 weight:s.fontWeight];
                NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
                style.alignment = s.textAlignment;

                NSDictionary *attrs = @{
                    NSForegroundColorAttributeName: s.textColor ?: UIColor.whiteColor,
                    NSFontAttributeName: font,
                    NSParagraphStyleAttributeName: style
                };

                CGSize textSize = [s.text sizeWithAttributes:attrs];
                CGFloat x = s.p1.x;
                if (s.textAlignment == NSTextAlignmentCenter) {
                    x -= textSize.width / 2.0;
                } else if (s.textAlignment == NSTextAlignmentRight) {
                    x -= textSize.width;
                }

                CGRect textRect = CGRectMake(x, s.p1.y, textSize.width, textSize.height);
                [s.text drawInRect:textRect withAttributes:attrs];
            } break;

        }
    }
}
@end
