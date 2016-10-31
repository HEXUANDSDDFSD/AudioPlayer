//
//  UIButton+Public.m
//  LocalStore
//
//  Created by hexuan on 16/8/17.
//  Copyright © 2016年 hexuan. All rights reserved.
//

#import "UIButton+public.h"

@implementation UIButton (Public)


+ (UIButton *)publicTestButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    return button;
}

+ (UIButton *)buttonWithBgImgName:(NSString *)imgName
                           target:(id)target
                       upInAction:(SEL)action
                        superView:(UIView *)superView {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setBackgroundImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [superView addSubview:button];
    return button;
}

@end
