//
//  IBView.h
//  WordFun
//
//  Created by 刘鹏i on 2018/6/21.
//  Copyright © 2018年 musjoy. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface IBView : UIView
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

@property (nonatomic, assign) IBInspectable BOOL semicircle;        ///< 始终一半高度的圆角

@property (nonatomic, assign) IBInspectable CGFloat cornerCoefficient;

@property (nonatomic, strong) IBInspectable UIColor *borderColor;
@end
