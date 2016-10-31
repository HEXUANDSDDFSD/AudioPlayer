//
//  SongManager.m
//  AudioPlayer
//
//  Created by hexuan on 16/10/30.
//  Copyright © 2016年 hexuan. All rights reserved.
//

#import "SongManager.h"
#import "APIStoreSDK.h"
#import "SongInfo.h"

#define kAPIStoreKey @"a024c65060b112f2c2836eae0ae91112"
#define kSongListRequestUrl @"http://apis.baidu.com/geekery/music/query"
#define kSongDesRequestUrl @"http://apis.baidu.com/geekery/music/playinfo"

@implementation SongManager {
    NSMutableArray *_songList;
    NSString *keyword;
    int currentPage;
    int currentSongIndex;
    int totalPage;
}

- (NSArray *)songList {
    return _songList;
}

- (BOOL)hasMore {
    return currentPage < totalPage;
}


- (instancetype)init {
    if (self = [super init]) {
        _songList = [NSMutableArray array];
    }
    return self;
}

- (void)getNetworkSongListWithKeyword:(NSString *)_keyword
                              complete:(void (^)(BOOL success))complete {
    APISCallBack *callBack = [[APISCallBack alloc] init];
    callBack.onSuccess = ^(long status, NSString* responseString) {
        
        NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![result[@"status"] isEqualToString:@"success"]) {
            if (complete) {
                complete(NO);
            }
            return;
        }
        NSArray *songs = result[@"data"][@"data"];
        totalPage = [result[@"data"][@"total_page"] intValue];
        currentPage = [result[@"data"][@"current_page"] intValue];
        
        for (int i = 0; i < [songs count]; i++) {
            NSDictionary *songInfoDic = songs[i];
            SongInfo *songInfo = [[SongInfo alloc] init];
            songInfo.songHash = songInfoDic[@"hash"];
            songInfo.singer = songInfoDic[@"singername"];
            songInfo.songName = songInfoDic[@"filename"];
            [_songList addObject:songInfo];
        }
        if (complete != NULL) {
            complete(YES);
        }
    };
    [ApiStoreSDK executeWithURL:kSongListRequestUrl
                         method:@"POST"
                         apikey:kAPIStoreKey
                      parameter:[@{@"page":[NSNumber numberWithInt:currentPage + 1],@"size":@20,@"s":[keyword stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]} mutableCopy]
                       callBack:callBack];
}

- (void)getFirstPageWithKeyword:(NSString *)_keyword complete:(void (^)(BOOL success))complete {
    keyword = _keyword;
    currentPage = 0;
    [_songList removeAllObjects];
    [self getNetworkSongListWithKeyword:keyword complete:complete];
}

- (void)loadMoreWithComplete:(void (^)(BOOL success))complete {
    [self getNetworkSongListWithKeyword:keyword complete:complete];
}

- (void)getSongUrlWithIndex:(int)index complete:(void (^)(BOOL, NSString*))complete {
    currentSongIndex = index;
    APISCallBack *callBack = [[APISCallBack alloc] init];
    callBack.onSuccess = ^(long status, NSString* responseString) {
        NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (complete) {
            if ([result[@"status"] isEqualToString:@"success"]) {
                complete(YES, result[@"data"][@"url"]);
            }
            else {
                complete(NO, nil);
            }
        }
    };
    SongInfo *songInfo = _songList[index];
    [ApiStoreSDK executeWithURL:kSongDesRequestUrl
                         method:@"POST"
                         apikey:kAPIStoreKey
                      parameter:[@{@"hash":songInfo.songHash} mutableCopy]
                       callBack:callBack];
}

- (void)getSwitchSongUrlWithSwitchType:(SMSwitchSongType)type
                              complete:(void (^)(BOOL success, NSString* url))complete {
    if (type == SMSwitchSongType_Last) {
        currentSongIndex--;
    }
    else {
        currentSongIndex++;
    }
    
    if (currentSongIndex < 0) {
        currentSongIndex = (int)([_songList count] - 1);
    }
    else if (currentSongIndex == [_songList count]) {
        currentSongIndex = 0;
    }
    [self getSongUrlWithIndex:currentSongIndex complete:^(BOOL success, NSString *url) {
        if (complete) {
            complete(success, url);
        }
    }];
}

@end
