//
//  DrawCardView.h
//  DrawCardAnimation
//
//  Created by 刘鹏i on 2018/12/19.
//  Copyright © 2018 wuhan.musjoy. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NSArray *(^GetResultBlock)(void);   // 获取卡牌结果回调
typedef void(^DidCompleteBlock)(void);      // 动画完成回调

NS_ASSUME_NONNULL_BEGIN
IB_DESIGNABLE
@interface DrawCardView : UIView
@property (nonatomic, assign) NSInteger cardCount;///< 牌数量
@property (nonatomic, assign) NSInteger angle;///< 展开角度

/**
 开始动画

 @param resultBlock 返回卡牌结果（图片名称数组）
 @param completion 动画全部完成回调
 */
- (void)startAnimation:(GetResultBlock)resultBlock completion:(DidCompleteBlock)completion;
@end

NS_ASSUME_NONNULL_END
