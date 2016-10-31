//
//  UIView+Frame.m
//  DataStructDemo
//
//  Created by hexuan on 16/8/21.
//  Copyright © 2016年 hexuan. All rights reserved.
//

#import "UIView+Frame.h"

@implementation UIView (Frame)

- (void)setX:(CGFloat)x {
    self.frame = CGRectMake(x, self.frame.origin.y, self.bounds.size.width, self.bounds.size.height);
}

- (void)setY:(CGFloat)y {
    self.frame = CGRectMake(self.frame.origin.x, y, self.bounds.size.width, self.bounds.size.height);
}

- (void)setWidth:(CGFloat)width {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.bounds.size.height);
}

- (void)setHeight:(CGFloat)height {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.bounds.size.width, height);
}

- (void)setRightX:(CGFloat)rightX {
    self.x = rightX - self.width;
}

- (void)setBottomY:(CGFloat)bottomY {
    self.y = bottomY - self.height;
}

- (CGFloat)x {
    return self.frame.origin.x;
}

- (CGFloat)y {
    return self.frame.origin.y;
}

- (CGFloat)width {
    return self.bounds.size.width;
}

- (CGFloat)height {
    return self.bounds.size.height;
}

- (CGFloat)rightX {
    return self.x + self.width;
}

- (CGFloat)bottomY {
    return self.y + self.height;
}


@end
