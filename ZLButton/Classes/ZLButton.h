//
//  ZLButton.h
//  ZLTagListView
//
//  Created by fanpeng on 2026/04/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 图片与文字的排列方向
typedef NS_ENUM(NSUInteger, ZLButtonAxis) {
    ZLButtonAxisHorizontal = 0,  // 水平排列
    ZLButtonAxisVertical,        // 垂直排列
};

/// 图片与文字的先后顺序
typedef NS_ENUM(NSUInteger, ZLButtonOrder) {
    ZLButtonOrderImageFirst = 0, // 图片在前（左/上）
    ZLButtonOrderTitleFirst,     // 文字在前（左/上）
};

/// 内容在按钮内的对齐方式（交叉轴）
typedef NS_ENUM(NSUInteger, ZLButtonContentAlignment) {
    ZLButtonContentAlignmentCenter = 0, // 居中
    ZLButtonContentAlignmentStart,      // 起始对齐（左/上）
    ZLButtonContentAlignmentEnd,        // 末尾对齐（右/下）
};

/**
 * ZLButton - 继承 UIButton，支持自定义图文布局
 *
 * 功能：
 * - 图片和文字可切换先后顺序（imageFirst / titleFirst）
 * - 支持水平或垂直排列
 * - 支持设置图文间距 (layoutSpacing)
 * - 支持弹性间距 (flexibleSpacing)，图文之间会尽可能撑满
 * - 完整支持 Auto Layout，intrinsicContentSize 自动撑开
 * - 支持 layoutEdgeInsets 设置内边距
 * - 支持固定图片大小 (layoutImageSize)
 * - 完整支持 RTL（阿拉伯语等从右到左语言）：
 *   · 水平布局自动镜像（图文顺序翻转）
 *   · Start/End 对齐自动翻转
 *   · layoutEdgeInsets 的 left/right 自动翻转
 *   · imageOffset/titleOffset 的水平方向自动翻转
 *
 * 注意：使用 UIButton 原生的 setTitle:forState: / setImage:forState: 设置内容，
 *       或使用便捷属性 layoutImage / layoutTitle。
 */
@interface ZLButton : UIButton
+ (instancetype)vertical; // 便捷方法，设置 layoutAxis = Vertical
+ (instancetype)horizontal; // 便捷方法，设置 layoutAxis = Horizontal
/// 排列方向，默认 Horizontal
@property (nonatomic, assign) ZLButtonAxis axis;
- (instancetype)vertical; // 便捷方法，设置 layoutAxis = Vertical
- (instancetype)horizontal; // 便捷方法，设置 layoutAxis = Horizontal

/// 图文顺序，默认 ImageFirst
@property (nonatomic, assign) ZLButtonOrder layoutOrder;
- (instancetype)imageFirst; // 便捷方法，设置 layoutOrder = ImageFirst
- (instancetype)titleFirst; // 便捷方法，设置 layoutOrder = TitleFirst

/// 内容对齐方式（在交叉轴上），默认 Center
@property (nonatomic, assign) ZLButtonContentAlignment layoutContentAlignment;
- (instancetype)alignCenter; // 便捷方法，设置 layoutContentAlignment = Center
- (instancetype)alignStart; // 便捷方法，设置 layoutContentAlignment = Start
- (instancetype)alignEnd; // 便捷方法，设置 layoutContentAlignment

/// 图文间距，默认 4
@property (nonatomic, assign) CGFloat layoutSpacing;

@property (nonatomic, copy,readonly) ZLButton* (^spacing)(CGFloat spacing);// layoutSpacing 的别名，便捷设置

/// 是否启用弹性间距（图文之间弹性撑满），默认 NO
/// 启用后 layoutSpacing 作为最小间距
@property (nonatomic, assign) BOOL flexibleSpacing;
- (instancetype)enableFlexibleSpacing; // 便捷方法，设置 flexibleSpacing = YES

/// 内边距，默认 UIEdgeInsetsZero
@property (nonatomic, assign) UIEdgeInsets layoutEdgeInsets;
@property (nonatomic, copy,readonly) ZLButton* (^insets)(CGFloat top,CGFloat leading,CGFloat bottom,CGFloat trailing);// layoutEdgeInsets 的别名，便捷设置

/// 图片固定大小，默认 CGSizeZero 表示使用图片自身大小
@property (nonatomic, assign) CGSize layoutImageSize;
@property (nonatomic, copy,readonly) ZLButton* (^imageSize)(CGFloat width,CGFloat height);// layoutImageSize 的别名，便捷设置

/// 便捷设置图片（设置 Normal 状态）
@property (nonatomic, strong, nullable) UIImage *layoutImage;
@property (nonatomic, copy,readonly) ZLButton* (^image)(id image);// layoutImage 的别名，便捷设置 UIImage 或 UIImageName
///选中图片
@property (nonatomic, copy, readonly)ZLButton* (^selectImage)(id image);// 便捷设置选中状态图片，支持 UIImage 或 UIImageName
/// 便捷设置标题（设置 Normal 状态）
@property (nonatomic, copy, nullable) NSString *layoutTitle;
@property (nonatomic, copy,readonly) ZLButton* (^title)(NSString *title);// layoutTitle 的别名，便捷设置
@property (nonatomic, copy, readonly)ZLButton* (^selectTitle)(NSString* title);
/// 便捷设置字体
@property (nonatomic, strong, nullable) UIFont *layoutTitleFont;
@property (nonatomic, copy,readonly) ZLButton* (^titleSysFont)(CGFloat fontSize);// layoutTitleFont 的别名，便捷设置
@property (nonatomic, copy,readonly) ZLButton* (^titleMedFont)(CGFloat fontSize);// layoutTitleFont 的别名，便捷设置
@property (nonatomic, copy,readonly) ZLButton* (^titleSemFont)(CGFloat fontSize);// layoutTitleFont 的别名，便捷设置
@property (nonatomic, copy,readonly) ZLButton* (^titleBoldFont)(CGFloat fontSize);// layoutTitleFont 的别名，便捷设置

/// 便捷设置字体颜色（设置 Normal 状态）
@property (nonatomic, strong, nullable) UIColor *layoutTitleColor;
@property (nonatomic, copy,readonly) ZLButton* (^titleColor)(id color);// layoutTitleColor 的别名，便捷设置 UIColor 或 UIColorHex
///设置选中文字颜色
@property (nonatomic, copy, readonly) ZLButton* (^selectTitleColor)(id color);
///设置文字换行最大宽度
@property (nonatomic, copy, readonly) ZLButton* (^titleMaxWidth)(CGFloat maxWidth);
///设置几行 文字，超过则换行，配合 titleMaxWidth 使用
@property (nonatomic, copy, readonly) ZLButton* (^titleLines)(NSInteger lines);
///设置背景色
@property (nonatomic, copy,readonly) ZLButton* (^bgColor)(id color);// 便捷设置背景色，支持 UIColor 或 UIColorHex

/// 图片偏移量（在布局计算完成后额外偏移），正值向右/下，负值向左/上 ，纯视觉偏移，不影响 intrinsicContentSize
@property (nonatomic, assign) UIOffset imageOffset;
@property (nonatomic, copy, readonly) ZLButton* (^imgOffset)(CGFloat horizontal, CGFloat vertical);

/// 文字偏移量（在布局计算完成后额外偏移），正值向右/下，负值向左/上，纯视觉偏移，不影响 intrinsicContentSize
@property (nonatomic, assign) UIOffset titleOffset;
@property (nonatomic, copy, readonly) ZLButton* (^titOffset)(CGFloat horizontal, CGFloat vertical);

/// 便捷设置点击事件，支持链式调用
@property (nonatomic,copy)ZLButton* (^touchAction)(void (^action)(ZLButton * button));

/// 设置图片模式
@property (nonatomic, copy, readonly) ZLButton* (^imageMode)(UIViewContentMode mode);
///UIViewContentModeScaleAspectFit
- (instancetype)imageModeScaleAspectFit;

///设置背景图片填充模式
@property (nonatomic, copy, readonly) ZLButton* (^bgImageMode)(UIViewContentMode mode);
- (instancetype)bgImageModeScaleAspectFit;

///设置是否可见
@property (nonatomic, copy, readonly) ZLButton* (^visibility)(BOOL visible);
///设置透明度
@property (nonatomic, copy, readonly) ZLButton* (^alphaValue)(CGFloat alpha);
///设置userinteractionEnabled
@property (nonatomic, copy, readonly) ZLButton* (^userInteraction)(BOOL userInteraction);
///设置选中
@property (nonatomic, copy, readonly) ZLButton* (^select)(BOOL select);
///设置圆角
@property (nonatomic, copy, readonly) ZLButton* (^cornerRadius)(CGFloat radius);

///设置4个方向的圆角，传入不同的值
@property (nonatomic, copy, readonly) ZLButton* (^cornerRadii)(CGFloat topLeft, CGFloat topRight, CGFloat bottomLeft, CGFloat bottomRight);

///设置是否圆形裁剪
@property (nonatomic, copy, readonly) ZLButton* (^circleClip)(BOOL circleClip);

///设置图片圆角
@property (nonatomic, copy, readonly) ZLButton* (^imageCornerRadius)(CGFloat radius);

///UIColor or #333333
@property (nonatomic,readonly) ZLButton* (^borderColor)(id);
@property (nonatomic,readonly) ZLButton* (^borderWidth)(CGFloat);
@property (nonatomic,readonly) ZLButton* (^shadowColor)(id color);
//默认 （0,2）
@property (nonatomic,readonly) ZLButton* (^shadowOffset)(CGFloat width,CGFloat height);
//默认0.2
@property (nonatomic,readonly) ZLButton* (^shadowOpacity)(CGFloat opacity);
//默认6
@property (nonatomic,readonly) ZLButton* (^shadowRadius)(CGFloat radius);
@property (nonatomic,readonly) ZLButton* (^masksToBounds)(BOOL masksToBounds);
///渐变层，外部可直接访问进行配置，例如设置渐变颜色、方向
@property (nonatomic,strong)CAGradientLayer *gradLayer;

///设置高度
@property (nonatomic, copy, readonly) ZLButton* (^heightEq)(CGFloat height);
///设置宽度
@property (nonatomic, copy, readonly) ZLButton* (^widthEq)(CGFloat width);
///同时设置宽高
@property (nonatomic, copy, readonly) ZLButton* (^sizeEq)(CGFloat width,CGFloat height);

///赋值当前对象到一个指针上
/// 例如：ZLButton *btn;
///  ZLButton.new.assignToPtr(&btn);
@property (nonatomic, copy, readonly) ZLButton* (^assignToPtr)(ZLButton *_Nullable* _Nullable buttonPtr);

///layoutsubview 回调
@property (nonatomic, copy) void (^layoutBlock)(ZLButton * button);
///dealloc回调
@property (nonatomic, copy) void (^deallocBlock)(ZLButton * button);
@end

NS_ASSUME_NONNULL_END
