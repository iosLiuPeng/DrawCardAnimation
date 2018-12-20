//
//  ContentView.h
//  DrawCardAnimation
//
//  Created by 刘鹏i on 2018/12/20.
//  Copyright © 2018 wuhan.musjoy. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ContentView : UIView
@property (nonatomic, copy) void(^layoutSubviewsBlock)(void);///< 更新回调
@end

NS_ASSUME_NONNULL_END
