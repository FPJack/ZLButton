//
//  ZLButton.m
//  ZLTagListView
//
//  Created by fanpeng on 2026/04/20.
//

#import "ZLButton.h"
#import <objc/runtime.h>
#define kRGBHexColor(hex) [UIColor colorWithRed:((CGFloat)((hex >> 16) & 0xFF)/255.0) green:((CGFloat)((hex >> 8) & 0xFF)/255.0) blue:((CGFloat)(hex & 0xFF)/255.0) alpha:1.0]
#define kRGBAHexColor(hex) [UIColor colorWithRed:((CGFloat)((hex >> 16) & 0xFF)/255.0) green:((CGFloat)((hex >> 8) & 0xFF)/255.0) blue:((CGFloat)(hex & 0xFF)/255.0) alpha:1.0]
static inline UIColor *__UIColorFromHexString(NSString *hexStr) {
    hexStr = [hexStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if([hexStr hasPrefix:@"0x"])hexStr = [hexStr substringFromIndex:2];
    if([hexStr hasPrefix:@"#"])hexStr = [hexStr substringFromIndex:1];
    unsigned int hexInt = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    [scanner scanHexInt:&hexInt];
    return hexStr.length > 6 ? kRGBAHexColor(hexInt) : kRGBHexColor(hexInt);
}

@interface ZLButton ()
/// 缓存的内容尺寸，避免重复计算
@property (nonatomic, assign) CGSize cachedImageSize;
@property (nonatomic, assign) CGSize cachedTitleSize;
@property (nonatomic, assign) BOOL needsRecalculate;
@property (nonatomic,weak)UILabel *lab;
@property (nonatomic,weak)UIImageView *imgView;
@property (nonatomic,copy)NSNumber* isCircleClip;
@property (nonatomic,assign)UIEdgeInsets cornerRadiiValue;
@end

@implementation ZLButton

#pragma mark - RTL Support

- (BOOL)_zl_isRTL {
    if (@available(iOS 10.0, *)) {
        return self.effectiveUserInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
    }
    return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

/// RTL 下翻转水平值
- (CGFloat)_zl_flipH:(CGFloat)value {
    return [self _zl_isRTL] ? -value : value;
}

/// RTL 下翻转 Start/End 对齐
- (ZLButtonContentAlignment)_zl_effectiveAlignment {
    if (![self _zl_isRTL]) return _layoutContentAlignment;
    switch (_layoutContentAlignment) {
        case ZLButtonContentAlignmentStart: return ZLButtonContentAlignmentEnd;
        case ZLButtonContentAlignmentEnd:   return ZLButtonContentAlignmentStart;
        default: return _layoutContentAlignment;
    }
}

/// RTL 下翻转 UIEdgeInsets 的 left/right
- (UIEdgeInsets)_zl_effectiveInsets {
    UIEdgeInsets insets = _layoutEdgeInsets;
    if ([self _zl_isRTL]) {
        CGFloat tmp = insets.left;
        insets.left = insets.right;
        insets.right = tmp;
    }
    return insets;
}

- (void)addSubview:(UIView *)view {
    [super addSubview: view];
    [self saveView:view];
}
- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index {
    [super insertSubview:view atIndex:index];
    [self saveView:view];
}
- (void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview {
    [super insertSubview:view aboveSubview:siblingSubview];
    [self saveView:view];
}
- (void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview {
    [super insertSubview:view belowSubview:siblingSubview];
    [self saveView:view];
}
- (void)saveView:(UIView *)view {
    if ([self.titleLabel isEqual:view]) {
        self.lab = (UILabel*)view;
    }
    if ([self.imageView isEqual:view]) {
        self.imgView = (UIImageView *)view;
    }
}
#pragma mark - Init
+ (instancetype)vertical {
    return [self buttonWithType:UIButtonTypeCustom].vertical;
}
+ (instancetype)horizontal {
    return [self buttonWithType:UIButtonTypeCustom].horizontal;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self _zl_setupDefaults];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self _zl_setupDefaults];
    return self;
}
- (CAGradientLayer *)gradLayer {
    if (!_gradLayer) {
        CAGradientLayer *layer = [CAGradientLayer layer];
        layer.startPoint = CGPointMake(0, 0); //左上
        layer.endPoint = CGPointMake(1, 1); // 右下
        _gradLayer = layer;
    }
    return _gradLayer;
}
- (void)_zl_setupDefaults {
    _axis = ZLButtonAxisHorizontal;
    _layoutOrder = ZLButtonOrderImageFirst;
    _layoutContentAlignment = ZLButtonContentAlignmentCenter;
    _layoutSpacing = 4;
    _flexibleSpacing = NO;
    _layoutEdgeInsets = UIEdgeInsetsZero;
    _layoutImageSize = CGSizeZero;
    _imageOffset = UIOffsetZero;
    _titleOffset = UIOffsetZero;
    _needsRecalculate = YES;
}

#pragma mark - Convenience Setters

- (void)setLayoutImage:(UIImage *)layoutImage {
    [self setImage:layoutImage forState:UIControlStateNormal];
    [self _zl_markDirty];
}
- (ZLButton * _Nonnull (^)(id _Nonnull))image {
    return ^(id img) {
        if ([img isKindOfClass:UIImage.class]) {
            self.layoutImage = img;
        } else if ([img isKindOfClass:NSString.class]) {
            self.layoutImage = [UIImage imageNamed:img];
        }else {
            self.layoutImage = nil;
        }
        return self;
    };
}
- (ZLButton * _Nonnull (^)(id _Nonnull))selectImage {
    return ^(id img) {
        if ([img isKindOfClass:UIImage.class]) {
            [self setImage:img forState:UIControlStateSelected];
        } else if ([img isKindOfClass:NSString.class]) {
            [self setImage:[UIImage imageNamed:img] forState:UIControlStateSelected];
        }else {
            [self setImage:nil forState:UIControlStateSelected];
        }
        [self _zl_markDirty];
        return self;
    };
}
- (UIImage *)layoutImage {
    return [self imageForState:UIControlStateNormal];
}

- (void)setLayoutTitle:(NSString *)layoutTitle {
    [self setTitle:layoutTitle forState:UIControlStateNormal];
    [self _zl_markDirty];
}

- (NSString *)layoutTitle {
    return [self titleForState:UIControlStateNormal];
}
- (ZLButton * _Nonnull (^)(NSString * _Nonnull))title {
    return ^(NSString *title) {
        self.layoutTitle = title;
        return self;
    };
}
- (ZLButton * _Nonnull (^)(NSString* _Nonnull))selectTitle {
    return ^(NSString* title) {
        if ([title isKindOfClass:NSString.class]) {
            [self setTitle:title forState:UIControlStateSelected];
        } else {
            [self setTitle:nil forState:UIControlStateSelected];
        }
        [self _zl_markDirty];
        return self;
    };
}
- (void)setLayoutTitleFont:(UIFont *)layoutTitleFont {
    self.titleLabel.font = layoutTitleFont;
    [self _zl_markDirty];
}
- (ZLButton * _Nonnull (^)(CGFloat))titleSysFont {
    return ^(CGFloat size) {
        self.layoutTitleFont = [UIFont systemFontOfSize:size];
        return self;
    };
}
- (ZLButton * _Nonnull (^)(CGFloat))titleMedFont {
    return ^(CGFloat size) {
        self.layoutTitleFont = [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
        return self;
    };
}
- (ZLButton * _Nonnull (^)(CGFloat))titleSemFont {
    return ^(CGFloat size) {
        self.layoutTitleFont = [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
        return self;
    };
}
- (ZLButton * _Nonnull (^)(CGFloat))titleBoldFont {
    return ^(CGFloat size) {
        self.layoutTitleFont = [UIFont systemFontOfSize:size weight:UIFontWeightBold];
        return self;
    };
}
- (UIFont *)layoutTitleFont {
    return self.titleLabel.font;
}

- (void)setLayoutTitleColor:(UIColor *)layoutTitleColor {
    [self setTitleColor:layoutTitleColor forState:UIControlStateNormal];
}
- (ZLButton * _Nonnull (^)(id _Nonnull))titleColor {
    return ^(id color) {
        self.layoutTitleColor = [self colorWithObj:color];
        return self;
    };
}
- (UIColor *)colorWithObj:(id)obj {
    UIColor *c;
    if ([obj isKindOfClass:UIColor.class]) {
        c = obj;
    } else if ([obj isKindOfClass:NSString.class]) {
        c = __UIColorFromHexString(obj);
    }
    return c;
}
- (ZLButton * _Nonnull (^)(id _Nonnull))selectTitleColor {
    return ^(id color) {
        UIColor *c = [self colorWithObj:color];
        [self setTitleColor:c forState:UIControlStateSelected];
        return self;
    };
}

- (ZLButton * _Nonnull (^)(CGFloat))titleMaxWidth {
    return ^(CGFloat maxWidth) {
        self.titleLabel.preferredMaxLayoutWidth = maxWidth;
        [self _zl_markDirty];
        return self;
    };
}
- (ZLButton * _Nonnull (^)(NSInteger))titleLines {
    return ^(NSInteger lines) {
        self.titleLabel.numberOfLines = lines;
        [self _zl_markDirty];
        return self;
    };
}
- (ZLButton * _Nonnull (^)(id _Nonnull))bgColor {
    return ^(id color) {
        self.backgroundColor = [self colorWithObj:color];
        return self;
    };
}
- (UIColor *)layoutTitleColor {
    return [self titleColorForState:UIControlStateNormal];
}

#pragma mark - Layout Property Setters

- (void)setAxis:(ZLButtonAxis)layoutAxis {
    if (_axis != layoutAxis) { _axis = layoutAxis; [self _zl_markDirty]; }
}
- (instancetype)vertical {
    self.axis = ZLButtonAxisVertical;
    return self;
}
- (instancetype)horizontal {
    self.axis = ZLButtonAxisHorizontal;
    return self;
}
- (void)setLayoutOrder:(ZLButtonOrder)layoutOrder {
    if (_layoutOrder != layoutOrder) { _layoutOrder = layoutOrder; [self _zl_markDirty]; }
}
- (instancetype)imageFirst {
    self.layoutOrder = ZLButtonOrderImageFirst;
    return self;
}
- (instancetype)titleFirst {
    self.layoutOrder = ZLButtonOrderTitleFirst;
    return self;
}
- (void)setLayoutContentAlignment:(ZLButtonContentAlignment)layoutContentAlignment {
    if (_layoutContentAlignment != layoutContentAlignment) { _layoutContentAlignment = layoutContentAlignment; [self setNeedsLayout]; }
}
- (instancetype)alignCenter {
    self.layoutContentAlignment = ZLButtonContentAlignmentCenter;
    return self;
}
- (instancetype)alignStart {
    self.layoutContentAlignment = ZLButtonContentAlignmentStart;
    return self;
}
- (instancetype)alignEnd {
    self.layoutContentAlignment = ZLButtonContentAlignmentEnd;
    return self;
}
- (void)setLayoutSpacing:(CGFloat)layoutSpacing {
    if (_layoutSpacing != layoutSpacing) { _layoutSpacing = layoutSpacing; [self _zl_markDirty]; }
}
- (ZLButton * _Nonnull (^)(CGFloat))spacing {
    return ^(CGFloat spacing) {
        self.layoutSpacing = spacing;
        return self;
    };
}

- (void)setFlexibleSpacing:(BOOL)flexibleSpacing {
    if (_flexibleSpacing != flexibleSpacing) { _flexibleSpacing = flexibleSpacing; [self _zl_markDirty]; }
}
- (instancetype)enableFlexibleSpacing {
    self.flexibleSpacing = YES;
    return self;
}
- (ZLButton * _Nonnull (^)(CGFloat, CGFloat, CGFloat, CGFloat))insets {
    return ^(CGFloat top, CGFloat leading, CGFloat bottom, CGFloat trailing) {
        self.layoutEdgeInsets = UIEdgeInsetsMake(top, leading, bottom, trailing);
        return self;
    };
}

- (void)setLayoutEdgeInsets:(UIEdgeInsets)layoutEdgeInsets {
    _layoutEdgeInsets = layoutEdgeInsets;
    [self _zl_markDirty];
}
- (void)setLayoutImageSize:(CGSize)layoutImageSize {
    _layoutImageSize = layoutImageSize;
    [self _zl_markDirty];
}
- (ZLButton * _Nonnull (^)(CGFloat, CGFloat))imageSize {
    return ^(CGFloat width, CGFloat height) {
        self.layoutImageSize = CGSizeMake(width, height);
        return self;
    };
}

- (void)setImageOffset:(UIOffset)imageOffset {
    _imageOffset = imageOffset;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (ZLButton * _Nonnull (^)(CGFloat, CGFloat))imgOffset {
    return ^(CGFloat horizontal, CGFloat vertical) {
        self.imageOffset = UIOffsetMake(horizontal, vertical);
        return self;
    };
}

- (void)setTitleOffset:(UIOffset)titleOffset {
    _titleOffset = titleOffset;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (ZLButton * _Nonnull (^)(CGFloat, CGFloat))titOffset {
    return ^(CGFloat horizontal, CGFloat vertical) {
        self.titleOffset = UIOffsetMake(horizontal, vertical);
        return self;
    };
}
- (ZLButton * _Nonnull (^)(void (^ _Nonnull)(ZLButton *)))touchAction {
    return ^(void (^action)(ZLButton *)) {
        [self addTarget:self action:@selector(_zl_handleTouch) forControlEvents:UIControlEventTouchUpInside];
        objc_setAssociatedObject(self, @selector(_zl_handleTouch), action, OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}
- (void)_zl_handleTouch {
    void (^action)(ZLButton *) = objc_getAssociatedObject(self, _cmd);
    if (action) action(self);
}
- (void)_zl_markDirty {
    _needsRecalculate = YES;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

#pragma mark - Size Calculation

- (void)_zl_recalculateIfNeeded {
    if (!_needsRecalculate) return;
    [self _zl_doRecalculate];
}

- (void)_zl_doRecalculate {
    _needsRecalculate = NO;

    UIImage *img = [self imageForState:self.state] ?: [self imageForState:UIControlStateNormal];
    if (img) {
        if (_layoutImageSize.width > 0 && _layoutImageSize.height > 0) {
            _cachedImageSize = _layoutImageSize;
        } else {
            _cachedImageSize = img.size;
        }
    } else {
        _cachedImageSize = CGSizeZero;
    }

    NSString *title = [self titleForState:self.state] ?: [self titleForState:UIControlStateNormal];
    NSAttributedString *attrTitle = [self attributedTitleForState:self.state] ?: [self attributedTitleForState:UIControlStateNormal];
    CGFloat maxWidth = CGFLOAT_MAX;
    if (self.titleLabel.preferredMaxLayoutWidth > 0) {
        maxWidth = self.titleLabel.preferredMaxLayoutWidth;
    } else if (self.titleLabel.numberOfLines == 1) {
        maxWidth = CGFLOAT_MAX;
    }else if(self.titleLabel.numberOfLines > 1) {
        maxWidth = self.bounds.size.width - _layoutEdgeInsets.left - _layoutEdgeInsets.right;
    }
    if (attrTitle.length > 0) {
        CGRect r = [attrTitle boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                           context:nil];
        _cachedTitleSize = CGSizeMake(ceil(r.size.width), ceil(r.size.height));
    } else if (title.length > 0) {
        UIFont *font = self.titleLabel.font ?: [UIFont systemFontOfSize:15];
        NSDictionary *attrs = @{NSFontAttributeName: font};
        CGRect r = [title boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:attrs
                                       context:nil];
        _cachedTitleSize = CGSizeMake(ceil(r.size.width), ceil(r.size.height));
    } else {
        _cachedTitleSize = CGSizeZero;
    }
}

- (BOOL)_zl_hasImage {
    return _cachedImageSize.width > 0 && _cachedImageSize.height > 0;
}

- (BOOL)_zl_hasTitle {
    return _cachedTitleSize.width > 0 && _cachedTitleSize.height > 0;
}

- (CGFloat)_zl_actualSpacing {
    return ([self _zl_hasImage] && [self _zl_hasTitle]) ? _layoutSpacing : 0;
}

#pragma mark - Intrinsic Content Size

- (CGSize)intrinsicContentSize {
    // 始终重新计算，避免标记被提前消费导致数据过期
    [self _zl_doRecalculate];

    CGSize imgSize = _cachedImageSize;
    CGSize txtSize = _cachedTitleSize;
    CGFloat sp = [self _zl_actualSpacing];
    UIEdgeInsets insets = _layoutEdgeInsets;

    CGFloat w, h;
    if (_axis == ZLButtonAxisHorizontal) {
        w = imgSize.width + sp + txtSize.width;
        h = MAX(imgSize.height, txtSize.height);
    } else {
        w = MAX(imgSize.width, txtSize.width);
        h = imgSize.height + sp + txtSize.height;
    }

    w += insets.left + insets.right;
    h += insets.top + insets.bottom;

    return CGSizeMake(ceil(w), ceil(h));
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self intrinsicContentSize];
}

#pragma mark - layoutSubviews

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /// 确保渐变层在最底层且尺寸正确
    if (!_gradLayer
        && !CGRectEqualToRect(self.bounds, CGRectZero)
        && !CGRectEqualToRect(self.bounds, self.gradLayer.bounds)) {
        [self.layer insertSublayer:self.gradLayer atIndex:0];
        self.gradLayer.frame = self.bounds;
    }
    
    if (self.isCircleClip) self.circleClip(self.isCircleClip);
    // 始终重新计算，确保动态修改内容后布局正确
    [self _zl_doRecalculate];

    CGRect bounds = self.bounds;
    UIEdgeInsets insets = [self _zl_effectiveInsets];
    CGRect contentRect = CGRectMake(insets.left, insets.top,
                                     MAX(0, bounds.size.width - insets.left - insets.right),
                                     MAX(0, bounds.size.height - insets.top - insets.bottom));

    CGSize imgSize = _cachedImageSize;
    CGSize txtSize = _cachedTitleSize;
    CGFloat sp = [self _zl_actualSpacing];

    BOOL hasImg = [self _zl_hasImage];
    BOOL hasTxt = [self _zl_hasTitle];
    BOOL isRTL = [self _zl_isRTL];

    UIImageView *imgView = self.imgView;
    UILabel *lblView = self.lab;

    if (!hasImg && !hasTxt) {
        imgView.frame = CGRectZero;
        lblView.frame = CGRectZero;
        [self callLayoutSubviewBlock];
        return;
    }

    if (!hasImg) {
        imgView.frame = CGRectZero;
        CGRect f = [self _zl_centeredRect:txtSize inRect:contentRect];
        f.origin.x += [self _zl_flipH:_titleOffset.horizontal];
        f.origin.y += _titleOffset.vertical;
        lblView.frame = f;
        [self callLayoutSubviewBlock];
        return;
    }
    if (!hasTxt) {
        lblView.frame = CGRectZero;
        CGRect f = [self _zl_centeredRect:imgSize inRect:contentRect];
        f.origin.x += [self _zl_flipH:_imageOffset.horizontal];
        f.origin.y += _imageOffset.vertical;
        imgView.frame = f;
        [self callLayoutSubviewBlock];
        return;
    }

    // 两个元素都有
    UIView *firstView, *secondView;
    CGSize firstSize, secondSize;

    if (_layoutOrder == ZLButtonOrderImageFirst) {
        firstView = imgView;  firstSize = imgSize;
        secondView = lblView; secondSize = txtSize;
    } else {
        firstView = lblView;  firstSize = txtSize;
        secondView = imgView; secondSize = imgSize;
    }

    if (_axis == ZLButtonAxisHorizontal) {
        if (isRTL) {
            // RTL: 翻转顺序，first 在右，second 在左
            [self _zl_layoutH_first:secondView fs:secondSize second:firstView ss:firstSize sp:sp rect:contentRect];
        } else {
            [self _zl_layoutH_first:firstView fs:firstSize second:secondView ss:secondSize sp:sp rect:contentRect];
        }
    } else {
        [self _zl_layoutV_first:firstView fs:firstSize second:secondView ss:secondSize sp:sp rect:contentRect];
    }

    // 应用偏移量（RTL 下翻转水平偏移）
    if (_imageOffset.horizontal != 0 || _imageOffset.vertical != 0) {
        CGRect f = imgView.frame;
        f.origin.x += [self _zl_flipH:_imageOffset.horizontal];
        f.origin.y += _imageOffset.vertical;
        imgView.frame = f;
    }
    if (_titleOffset.horizontal != 0 || _titleOffset.vertical != 0) {
        CGRect f = lblView.frame;
        f.origin.x += [self _zl_flipH:_titleOffset.horizontal];
        f.origin.y += _titleOffset.vertical;
        lblView.frame = f;
    }
    [self callLayoutSubviewBlock];
}
- (void)callLayoutSubviewBlock {
    [self drawCornerRadii];
    if (self.layoutBlock) {
        self.layoutBlock(self);
    }
}
// Remove the old adjustImageOffset / adjustTitleOffset methods — inlined above

#pragma mark - Horizontal Layout

- (void)_zl_layoutH_first:(UIView *)first fs:(CGSize)fs second:(UIView *)second ss:(CGSize)ss sp:(CGFloat)sp rect:(CGRect)rect {
    CGFloat totalW = fs.width + sp + ss.width;
    CGFloat actualSp = sp;
    CGFloat startX;

    if (_flexibleSpacing) {
        actualSp = MAX(sp, rect.size.width - fs.width - ss.width);
        startX = rect.origin.x;
    } else {
        startX = rect.origin.x + (rect.size.width - totalW) / 2.0;
    }

    CGFloat firstY  = [self _zl_alignedOrigin:fs.height container:rect.size.height offset:rect.origin.y];
    CGFloat secondY = [self _zl_alignedOrigin:ss.height container:rect.size.height offset:rect.origin.y];

    first.frame  = CGRectMake(startX, firstY, fs.width, fs.height);
    second.frame = CGRectMake(startX + fs.width + actualSp, secondY, ss.width, ss.height);
}

#pragma mark - Vertical Layout

- (void)_zl_layoutV_first:(UIView *)first fs:(CGSize)fs second:(UIView *)second ss:(CGSize)ss sp:(CGFloat)sp rect:(CGRect)rect {
    CGFloat totalH = fs.height + sp + ss.height;
    CGFloat actualSp = sp;
    CGFloat startY;

    if (_flexibleSpacing) {
        actualSp = MAX(sp, rect.size.height - fs.height - ss.height);
        startY = rect.origin.y;
    } else {
        startY = rect.origin.y + (rect.size.height - totalH) / 2.0;
    }

    CGFloat firstX  = [self _zl_alignedOrigin:fs.width container:rect.size.width offset:rect.origin.x];
    CGFloat secondX = [self _zl_alignedOrigin:ss.width container:rect.size.width offset:rect.origin.x];

    first.frame  = CGRectMake(firstX, startY, fs.width, fs.height);
    second.frame = CGRectMake(secondX, startY + fs.height + actualSp, ss.width, ss.height);
}

#pragma mark - Helpers

- (CGFloat)_zl_alignedOrigin:(CGFloat)itemLen container:(CGFloat)containerLen offset:(CGFloat)offset {
    ZLButtonContentAlignment alignment = [self _zl_effectiveAlignment];
    switch (alignment) {
        case ZLButtonContentAlignmentStart:
            return offset;
        case ZLButtonContentAlignmentEnd:
            return offset + containerLen - itemLen;
        case ZLButtonContentAlignmentCenter:
        default:
            return offset + (containerLen - itemLen) / 2.0;
    }
}

- (CGRect)_zl_centeredRect:(CGSize)size inRect:(CGRect)rect {
    return CGRectMake(rect.origin.x + (rect.size.width - size.width) / 2.0,
                      rect.origin.y + (rect.size.height - size.height) / 2.0,
                      size.width, size.height);
}


- (ZLButton * _Nonnull (^)(UIViewContentMode))imageMode {
    return ^(UIViewContentMode mode) {
        self.imageView.contentMode = mode;
        return self;
    };
}
- (ZLButton * _Nonnull (^)(BOOL))visibility {
    return ^(BOOL visible) {
        self.hidden = !visible;
        return self;
    };
}
- (ZLButton * _Nonnull (^)(CGFloat))alphaValue {
    return ^(CGFloat alpha) {
        self.alpha = alpha;
        return self;
    };
}
- (instancetype)imageModeScaleAspectFit {
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    return self;
}
- (ZLButton * _Nonnull (^)(UIViewContentMode))bgImageMode {
    return ^(UIViewContentMode mode) {
        self.contentMode = mode;
        return self;
    };
}
- (instancetype)bgImageModeScaleAspectFit {
    self.contentMode = UIViewContentModeScaleAspectFit;
    return self;
}
- (ZLButton * _Nonnull (^)(BOOL))userInteraction {
    return ^(BOOL enabled) {
        self.userInteractionEnabled = enabled;
        return self;
    };
}
- (ZLButton * _Nonnull (^)(BOOL))select {
    return ^(BOOL selected) {
        self.selected = selected;
        return self;
    };
}
- (ZLButton * _Nonnull (^)(CGFloat))cornerRadius {
    return ^ZLButton*(CGFloat radius){
        self.layer.cornerRadius = radius;
        self.layer.masksToBounds = radius > 0;
        return self;
    };
}
- (ZLButton * _Nonnull (^)(CGFloat, CGFloat, CGFloat, CGFloat))cornerRadii {
    return ^ZLButton*(CGFloat topLeft, CGFloat topRight, CGFloat bottomLeft, CGFloat bottomRight){
        self.cornerRadiiValue = UIEdgeInsetsMake(topLeft, topRight, bottomLeft, bottomRight);
        return self;
    };
}
- (void)drawCornerRadii {
    if (UIEdgeInsetsEqualToEdgeInsets(self.cornerRadiiValue, UIEdgeInsetsZero)) {
        return;
    }
    CGFloat topLeft, topRight, bottomLeft, bottomRight;
    if ([self _zl_isRTL]) {
        topLeft = self.cornerRadiiValue.left;      // original topRight
        topRight = self.cornerRadiiValue.top;       // original topLeft
        bottomLeft = self.cornerRadiiValue.right;   // original bottomRight
        bottomRight = self.cornerRadiiValue.bottom;  // original bottomLeft
    } else {
        topLeft = self.cornerRadiiValue.top;
        topRight = self.cornerRadiiValue.left;
        bottomLeft = self.cornerRadiiValue.bottom;
        bottomRight = self.cornerRadiiValue.right;
    }
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGSize size = self.bounds.size;
    [path moveToPoint:CGPointMake(0, topLeft)];
    [path addQuadCurveToPoint:CGPointMake(topLeft, 0) controlPoint :CGPointMake(0, 0)];
    [path addLineToPoint:CGPointMake(size.width - topRight, 0)];
    [path addQuadCurveToPoint:CGPointMake(size.width, topRight) controlPoint:CGPointMake(size.width, 0)];
    [path addLineToPoint:CGPointMake(size.width, size.height - bottomRight)];
    [path addQuadCurveToPoint:CGPointMake(size.width - bottomRight, size.height) controlPoint:CGPointMake(size.width, size.height)];
    [path addLineToPoint:CGPointMake(bottomLeft, size.height)];
    [path addQuadCurveToPoint:CGPointMake(0, size.height - bottomLeft) controlPoint:CGPointMake(0, size.height)];
    [path closePath];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.bounds;
    maskLayer.path = path.CGPath;
    self.layer.mask = maskLayer;
}
- (ZLButton * _Nonnull (^)(BOOL))circleClip {
    return ^ZLButton*(BOOL clip) {
        self.isCircleClip = @(clip);
        if (clip) {
            CGFloat minSide = MIN(self.bounds.size.width, self.bounds.size.height);
            self.layer.cornerRadius = minSide / 2.0;
            self.layer.masksToBounds = YES;
        } else {
            self.layer.cornerRadius = 0;
            self.layer.masksToBounds = NO;
        }
        return self;
    };
}
- (ZLButton * _Nonnull (^)(CGFloat))imageCornerRadius {
    return ^ZLButton*(CGFloat radius){
        self.imageView.layer.cornerRadius = radius;
        self.imageView.layer.masksToBounds = radius > 0;
        return self;
    };
}
- (ZLButton* (^)(id ))borderColor {
    return  ^ZLButton*(id color){
        self.layer.borderColor = [self colorWithObj:color].CGColor;
        return self;
    };
}
- (ZLButton* (^)(CGFloat ))borderWidth {
    return  ^ZLButton*(CGFloat width){
        self.layer.borderWidth = width;
        return self;
    };
}

- (ZLButton*  _Nonnull (^)(id _Nonnull))shadowColor {
    return ^ZLButton* (id color) {
        self.layer.shadowColor = [self colorWithObj:color].CGColor;
        return self.shadowOffset(0,2);
    };
}


- (ZLButton*  _Nonnull (^)(CGFloat, CGFloat))shadowOffset {
    return ^ZLButton* (CGFloat width, CGFloat height) {
        self.layer.shadowOffset = CGSizeMake(width, height);
        return self.shadowRadius(6);
    };
}


- (ZLButton*  _Nonnull (^)(CGFloat))shadowRadius {
    return ^ZLButton* (CGFloat radius) {
        self.layer.shadowRadius = radius;
        return self.shadowOpacity(0.2);
    };
}

- (ZLButton*  _Nonnull (^)(CGFloat))shadowOpacity {
    return ^ZLButton* (CGFloat opacity) {
        self.layer.shadowOpacity = opacity;
        return self.masksToBounds(NO);
    };
}
- (ZLButton*  _Nonnull (^)(BOOL))masksToBounds {
    return ^ZLButton* (BOOL masks) {
        self.layer.masksToBounds = masks;
        return self;
    };
}
- (ZLButton * _Nonnull (^)(CGFloat))heightEq {
    return ^ZLButton*(CGFloat height){
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self deactivieConstraints:NSLayoutAttributeHeight relation:NSLayoutRelationEqual];
        [self.heightAnchor constraintEqualToConstant:height].active = YES;
        return self;
    };
}
- (ZLButton * _Nonnull (^)(CGFloat))widthEq {
    return ^ZLButton*(CGFloat width){
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self deactivieConstraints:NSLayoutAttributeWidth relation:NSLayoutRelationEqual];
        [self.widthAnchor constraintEqualToConstant:width].active = YES;
        return self;
        };
}
- (void)deactivieConstraints:(NSLayoutAttribute)attribute relation:(NSLayoutRelation)relation {
    [self.constraints enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof NSLayoutConstraint * _Nonnull constraint, NSUInteger idx, BOOL * _Nonnull stop) {
        if (constraint.firstAttribute == attribute &&
            [constraint.firstItem isEqual:self] &&
            constraint.relation == relation &&
            constraint.secondItem == nil) {
            constraint.active = NO;
            [self removeConstraint:constraint];
        }
    }];
}
- (ZLButton * _Nonnull (^)(CGFloat, CGFloat))sizeEq {
    return ^ZLButton*(CGFloat width, CGFloat height){
        return self.widthEq(width).heightEq(height);
    };
}
- (ZLButton * _Nonnull (^)(ZLButton * _Nullable __autoreleasing * _Nullable))toPtr {
    return ^ZLButton*(ZLButton **ptr){
        if (ptr) *ptr = self;
        return self;
    };
}
- (void)dealloc
{
    if (self.deallocBlock) self.deallocBlock(self);
}
@end
