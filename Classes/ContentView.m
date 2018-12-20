//
//  ContentView.m
//  DrawCardAnimation
//
//  Created by 刘鹏i on 2018/12/20.
//  Copyright © 2018 wuhan.musjoy. All rights reserved.
//

#import "ContentView.h"

@implementation ContentView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_layoutSubviewsBlock) {
        _layoutSubviewsBlock();
    }
    
}
@end
