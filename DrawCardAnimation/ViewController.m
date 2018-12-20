//
//  ViewController.m
//  DrawCardAnimation
//
//  Created by 刘鹏i on 2018/12/19.
//  Copyright © 2018 wuhan.musjoy. All rights reserved.
//

#import "ViewController.h"
#import "DrawCardView.h"

@interface ViewController ()
@property (nonatomic, strong) IBOutlet DrawCardView *viewCard;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)startAnimatio:(id)sender
{
    [_viewCard startAnimation:^NSArray *{
        return @[@"tarot_1", @"tarot_2", @"tarot_3"];
    } completion:^{
        NSLog(@"动画已经全部完成~\(≧▽≦)/~啦啦啦");
    }];
}

@end
