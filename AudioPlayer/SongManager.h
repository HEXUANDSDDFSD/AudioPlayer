//
//  SongManager.h
//  AudioPlayer
//
//  Created by hexuan on 16/10/30.
//  Copyright © 2016年 hexuan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SMSwitchSongType_Last,
    SMSwitchSongType_next
}SMSwitchSongType;

@interface SongManager : NSObject

@property (nonatomic, readonly) NSArray *songList;
@property (nonatomic, readonly) BOOL hasMore;

- (void)getFirstPageWithKeyword:(NSString *)_keyword complete:(void (^)(BOOL success))complete;
- (void)loadMoreWithComplete:(void (^)(BOOL success))complete;

- (void)getSongUrlWithIndex:(int)index
                   complete:(void (^)(BOOL success, NSString* url))complete;

- (void)getSwitchSongUrlWithSwitchType:(SMSwitchSongType)type
                              complete:(void (^)(BOOL success, NSString* url))complete;

@end
