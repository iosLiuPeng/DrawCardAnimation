//
//  DrawCardView.m
//  DrawCardAnimation
//
//  Created by 刘鹏i on 2018/12/19.
//  Copyright © 2018 wuhan.musjoy. All rights reserved.
//

#import "DrawCardView.h"
#import "ContentView.h"

/// 牌堆状态
typedef NS_ENUM(NSUInteger, CardStatus) {
    CardStatus_NotStart,    ///< 未开始
    CardStatus_DidExtend,   ///< 已展开
};

/// 动画状态
typedef NS_ENUM(NSUInteger, AnimationStatus) {
    AnimationStatus_Start,       ///< 已开始
    AnimationStatus_WaitMoveUp,  ///< 待上移
    AnimationStatus_DidMoveUp,   ///< 已上移
    AnimationStatus_WaitDismiss, ///< 将要消失
    AnimationStatus_DidDismiss,  ///< 已经消失
};

@interface DrawCardView () <CAAnimationDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *imgCardCenter;  ///< 初始牌堆
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *lytImgCardCenter;
@property (strong, nonatomic) IBOutlet UILabel *lblTip;             ///< 提示

@property (strong, nonatomic) IBOutlet UIStackView *stackView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *lytStackCenter;
@property (strong, nonatomic) IBOutlet UIView *viewCard1;           ///< 卡牌视图1
@property (strong, nonatomic) IBOutlet UIView *viewBorder1;         ///< 边框1
@property (strong, nonatomic) IBOutlet UIView *viewCardBg1;         ///< 卡牌背景图1
@property (strong, nonatomic) IBOutlet UILabel *lblDrag1;           ///< 拖拽提示1
@property (strong, nonatomic) IBOutlet UIImageView *imgCard1;       ///< 卡片背景1
@property (strong, nonatomic) IBOutlet UILabel *lblCardTitle1;      ///< 类别1

@property (strong, nonatomic) IBOutlet UIView *viewCard2;
@property (strong, nonatomic) IBOutlet UIView *viewBorder2;
@property (strong, nonatomic) IBOutlet UIView *viewCardBg2;
@property (strong, nonatomic) IBOutlet UILabel *lblDrag2;
@property (strong, nonatomic) IBOutlet UIImageView *imgCard2;
@property (strong, nonatomic) IBOutlet UILabel *lblCardTitle2;

@property (strong, nonatomic) IBOutlet UIView *viewCard3;
@property (strong, nonatomic) IBOutlet UIView *viewBorder3;
@property (strong, nonatomic) IBOutlet UIView *viewCardBg3;
@property (strong, nonatomic) IBOutlet UILabel *lblDrag3;
@property (strong, nonatomic) IBOutlet UIImageView *imgCard3;
@property (strong, nonatomic) IBOutlet UILabel *lblCardTitle3;

@property (nonatomic, assign) NSInteger currentIndex;       ///< 当前选第几张牌
@property (nonatomic, strong) NSMutableArray *arrCard;      ///< 所有卡牌
@property (nonatomic, assign) CardStatus status;            ///< 牌堆状态
@property (nonatomic, assign) AnimationStatus animStatus;   ///< 动画状态
@property (nonatomic, assign) CGPoint beforeCenter;///< 上移之前的牌堆中心点

@property (nonatomic, copy) GetResultBlock resultBlock;///< 获取卡牌结果回调
@property (nonatomic, copy) DidCompleteBlock completeBlock;///< 动画完成回调
@end

#define ExtendAnimationKey @"ExtendAnimationKey"/// 展开动画key
#define ScaleAnimationKey @"ScaleAnimationKey"/// 放大动画key

@implementation DrawCardView
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self loadViewFromXib];
        [self viewConfg];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self loadViewFromXib];
        [self viewConfg];
    }
    return self;
}

- (void)loadViewFromXib
{
    ContentView *contentView = [[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil].firstObject;
    
    contentView.frame = self.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight;
    [self addSubview:contentView];
    
    // 子视图布局更新
    __weak typeof(self) weakSelf = self;
    contentView.layoutSubviewsBlock = ^{
        if (weakSelf.animStatus == AnimationStatus_WaitMoveUp) {
            // 待上移
            // 上移动画
            [self startTranslationAnimation];
        } else if (weakSelf.animStatus == AnimationStatus_WaitDismiss) {
            // 待消失
            // 什么也不做
            weakSelf.animStatus = AnimationStatus_DidDismiss;
        } else {
            // 其他，重新布局
            for (NSInteger i = 0; i < weakSelf.arrCard.count; i++) {
                UIImageView *view = weakSelf.arrCard[i];
                if (weakSelf.status == CardStatus_NotStart) {
                    // 初始
                    view.frame = weakSelf.imgCardCenter.frame;
                } else {
                    // 展开
                    [weakSelf startCardExtendAnimation];
                }
            }
        }
    };
}

#pragma mark - Subjoin
- (void)viewConfg
{
    _imgCardCenter.hidden = YES;  ///< 初始牌堆
    _lblTip.hidden = YES;
    _stackView.hidden = YES;

//    // 拖拽提示
//    _lblDrag1;
//    _lblDrag2;
//    _lblDrag3;
//
//    // 类别
//    _lblCardTitle1;
//    _lblCardTitle2;
//    _lblCardTitle3;
    
    // 牌数量
    if (_cardCount <= 0) {
        _cardCount = 22;
    }

    // 展开角度
    if (_angle <= 0) {
        _angle = 80;
    }
    
    self.currentIndex = 1;
}

#pragma mark - Private
/// 创建牌堆
- (void)createCardPile
{
    _arrCard = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < _cardCount; i++) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tarot_bg"]];
        imgView.frame = _imgCardCenter.frame;
        imgView.tag = 100 + i;
        [self addSubview:imgView];
        
        [_arrCard addObject:imgView];
    }
}

/// 对应序号(1~n)卡片的路径
- (UIBezierPath *)pathWithIndex:(NSInteger)index
{
    CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) / 2.0;  // 半径
    CGPoint center = CGPointMake(_imgCardCenter.center.x, _imgCardCenter.center.y + radius);
    CGFloat startAngle = -M_PI_2;   // 起点角度
    CGFloat endAngle = -M_PI_2 + [self angleWithIndex:index]; // 终点角度
    BOOL clockwise = index > _cardCount / 2? NO: YES;   // 绘制方向
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:clockwise];
    return path;
}

/// 对应序号(1~n)卡片的旋转角度
- (CGFloat)angleWithIndex:(NSInteger)index
{
    // 在iOS中，正值表示逆时针旋转，负值表示顺时针旋转。
    CGFloat angle = 0;
    
    CGFloat intervalAngle = _angle * 1.0 / (_cardCount - 1);  // 两张牌之间间隔的角度
    NSInteger halfCount = _cardCount / 2;    // 牌堆数量一半
    
    if (_cardCount % 2 == 1) {
        // 单数牌堆
        if (index != halfCount + 1) {
            angle = (halfCount - index + 1) * intervalAngle;
        } else {
            angle = 0;
        }
    } else {
        // 双数
        angle = (halfCount - index + 0.5) * intervalAngle;
    }
    
    return angle / 180 * M_PI;
}

/// 对应序号(1~n)卡片的终点位置
- (CGPoint)finallyCenter:(NSInteger)index
{
    UIBezierPath *path = [self pathWithIndex:index];
    return path.currentPoint;
}

#pragma mark - Set
/// 当前选到第几张牌
- (void)setCurrentIndex:(NSInteger)currentIndex
{
    _currentIndex = currentIndex;
    
    NSInteger index = currentIndex - 1;
    
    // 选牌
    NSArray *arrBorder = @[_viewBorder1, _viewBorder2, _viewBorder3];
    NSArray *arrCardBg = @[_imgCard1, _imgCard2, _imgCard3];
    NSArray *arrLabel = @[_lblDrag1, _lblDrag2, _lblDrag3];
    NSArray *arrBg = @[_viewCardBg1, _viewCardBg2, _viewCardBg3];
    NSArray *arrTips = @[@"Choose The Love Card", @"Choose The Fortune Card", @"Choose The Career Card"];
    
    for (NSInteger i = 0; i < 3; i++) {
        UIView *border = arrBorder[i];
        border.hidden = index == i? NO: YES;
        
        UILabel *label = arrLabel[i];
        label.hidden = index == i? NO: YES;
        
        UIImageView *imgBg = arrCardBg[i];
        imgBg.hidden = i < index ? NO: YES;
        
        UIView *bg = arrBg[i];
        bg.hidden = i < index ? YES: NO;
    }
    
    if (index < 3) {
        _lblTip.text = arrTips[index];
    } else {
        // 选牌结束
        _lblTip.hidden = YES;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 牌堆消失、已选卡上移动画
            [self startDismissAnimation];
        });
    }
}

#pragma mark - Action
- (void)panGestureAction:(UIPanGestureRecognizer *)pan
{
    CGPoint translatePoint = [pan translationInView:self];
    NSInteger index = pan.view.tag - 100;
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            // 开始
            pan.view.transform = CGAffineTransformIdentity;
            break;
        case UIGestureRecognizerStateChanged:
            // 移动
            pan.view.transform = CGAffineTransformMakeTranslation(translatePoint.x, translatePoint.y);
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            // 结束
        {
            // 当前点
            CGPoint currentPoint = CGPointMake(pan.view.center.x + translatePoint.x, pan.view.center.y + translatePoint.y);
            // 目标点
            NSArray *arrView = @[_viewCard1, _viewCard2, _viewCard3];
            UIView *cardView = arrView[self.currentIndex - 1];
            CGPoint targetPoint = [cardView.superview convertPoint:cardView.center toView:self];
            
            if (fabs(currentPoint.x - targetPoint.x) <= 20 && fabs(currentPoint.y - targetPoint.y) <= 30) {
                // 在有效范围内
                pan.view.transform = CGAffineTransformIdentity;
                pan.view.center = targetPoint;
                pan.view.userInteractionEnabled = NO;
                // 放大动画
                [self startScaleAnimtionWithIndex:index targetBounds:cardView.bounds];
            } else {
                // 不在有效范围内，卡牌退回
                pan.view.transform = CGAffineTransformIdentity;
                pan.view.transform = CGAffineTransformMakeRotation([self angleWithIndex:_cardCount - index]);
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - Overwrite


#pragma mark - Animation
/**
 开始动画
 
 @param resultBlock 返回卡牌结果（图片名称数组）
 @param completion 动画全部完成回调
 */
- (void)startAnimation:(GetResultBlock)resultBlock completion:(DidCompleteBlock)completion
{
    _resultBlock = resultBlock;
    _completeBlock = completion;
    
    // 创建牌堆
    [self createCardPile];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 牌堆展开动画
        [self startCardExtendAnimation];
    });
}

/// 上移动画
- (void)startTranslationAnimation
{
    CGPoint offset = CGPointMake(_imgCardCenter.center.x - _beforeCenter.x, _imgCardCenter.center.y - _beforeCenter.y);
    _stackView.alpha = 0.0;
    _stackView.hidden = NO;
    
    [UIView animateWithDuration:2 animations:^{
        for (UIImageView *imgView in self.arrCard) {
            imgView.center = CGPointMake(imgView.center.x + offset.x, imgView.center.y + offset.y);
        }
        
        self.stackView.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.lblTip.hidden = NO;
        
        for (UIImageView *imgView in self.arrCard) {
            imgView.userInteractionEnabled = YES;
        }
    }];
}

/// 牌堆展开动画
- (void)startCardExtendAnimation
{
    _status = CardStatus_DidExtend;
    
    for (NSInteger i = 0; i < _cardCount; i++) {
        UIImageView *imgView = _arrCard[i];
        
        CAKeyframeAnimation *pathAnima = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        pathAnima.path = [self pathWithIndex:_cardCount - i].CGPath;

        CABasicAnimation *rotaAnima = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        rotaAnima.toValue = @([self angleWithIndex:_cardCount - i]);

        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.delegate = self;
        group.animations = @[pathAnima, rotaAnima];
        group.duration = 1.0;
        group.fillMode = kCAFillModeForwards;
        group.removedOnCompletion = NO;
        group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        
        [group setValue:[NSString stringWithFormat:@"%ld", (long)(i + 100)] forKey:ExtendAnimationKey];
        [imgView.layer addAnimation:group forKey:nil];
    }
}

/// 放大动画
- (void)startScaleAnimtionWithIndex:(NSInteger)index targetBounds:(CGRect)bounds
{
    UIView *view = _arrCard[index];
    
    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"bounds"];
    anima.toValue = [NSValue valueWithCGRect:bounds];
    anima.duration = 0.15;
    anima.delegate = self;
    anima.fillMode = kCAFillModeForwards;
    anima.removedOnCompletion = NO;
    anima.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    [anima setValue:[NSString stringWithFormat:@"%ld", (long)(index + 1000)] forKey:ScaleAnimationKey];
    [view.layer addAnimation:anima forKey:nil];
}

/// 翻牌动画
- (void)startFlipAnimation:(NSArray *)arrName
{
    if (arrName.count < 3) {
        // 直接结束
        if (self.completeBlock) {
            self.completeBlock();
            self.completeBlock = nil;
        }
        
        return;
    }
    
    NSArray *arrCardBg = @[_imgCard1, _imgCard2, _imgCard3];
    
    for (NSInteger i = 0; i < arrCardBg.count; i++) {
        UIImageView *imgView = arrCardBg[i];
        NSString *name = arrName[i];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * 0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView transitionWithView:imgView duration:1.0 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                imgView.image = [UIImage imageNamed:name];
            } completion:^(BOOL finished) {
                if (i == 2) {
                    // 全部结束
//                    self.hidden = YES;
                    
                    // 回调
                    if (self.completeBlock) {
                        self.completeBlock();
                        self.completeBlock = nil;
                    }
                }
            }];
        });
    }
}

/// 牌堆消失、已选卡上移动画
- (void)startDismissAnimation
{
    // 已选卡上移动画
    _animStatus = AnimationStatus_WaitDismiss;
    _lytStackCenter.active = NO;
    [self setNeedsLayout];
    
    [UIView animateWithDuration:2.0 animations:^{
        [self layoutIfNeeded];
    }];
    
    // 牌堆消失
    CGFloat offset = self.bounds.size.height / 2.0;
    [UIView animateWithDuration:2.0 animations:^{
        for (UIImageView *imgView in self.arrCard) {
            imgView.center = CGPointMake(imgView.center.x, imgView.center.y - offset);
            imgView.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSArray *arrName = nil;
            
            if (self.resultBlock) {
                arrName = self.resultBlock();
            }
    
            // 翻牌动画
            [self startFlipAnimation:arrName];
        });
    }];
}

#pragma mark - CAAnimationDelegate
/// 动画结束
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSInteger index = [[anim valueForKey:ExtendAnimationKey] integerValue];
    if (index >= 100 && index < 1000) {
        // 展开动画
        index -= 100;
        UIImageView *imgView = _arrCard[index];
        
        imgView.center = [self pathWithIndex:_cardCount - index].currentPoint;
        imgView.transform = CGAffineTransformMakeRotation([self angleWithIndex:_cardCount - index]);
        [imgView.layer removeAllAnimations];
        
        if (imgView.gestureRecognizers.count == 0) {
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
            [imgView addGestureRecognizer:pan];
        }
        
        if (index == 0) {
            // 刷新布局
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.beforeCenter = self.imgCardCenter.center;
                self.animStatus = AnimationStatus_WaitMoveUp;
                self.lytImgCardCenter.active = NO;
                [self setNeedsLayout];
                [self layoutSubviews];
            });
        }
    }
    
    index = [[anim valueForKey:ScaleAnimationKey] integerValue];
    if (index >= 1000 && index < 2000) {
        // 放大动画
        index -= 1000;
        UIImageView *imgView = _arrCard[index];
        imgView.hidden = YES;
        [imgView.layer removeAllAnimations];
        
        self.currentIndex += 1;
    }
}


@end
