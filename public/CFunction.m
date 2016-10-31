//
//  CFunction.m
//  AudioPlayer
//
//  Created by hexuan on 16/10/30.
//  Copyright © 2016年 hexuan. All rights reserved.
//

#import "CFunction.h"

void runInMainThread(void (^func)()) {
    dispatch_async(dispatch_get_main_queue(), func);
}
