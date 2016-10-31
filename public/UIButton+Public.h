//
//  UIButton+Public.h
//  LocalStore
//
//  Created by hexuan on 16/8/17.
//  Copyright © 2016年 hexuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (Public)

+ (UIButton *)publicTestButtonWithTitle:(NSString *)title;

+ (UIButton *)buttonWithBgImgName:(NSString *)imgName
target:(id)target
upInAction:(SEL)action
superView:(UIView *)superView;

@end
