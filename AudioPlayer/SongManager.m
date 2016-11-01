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
#define kSongLrcRequestUrl @"http://apis.baidu.com/geekery/music/krc"
#define kSingerInfoRequestUrl @"http://apis.baidu.com/geekery/music/singer"

@implementation SongManager {
    NSMutableArray *_songList;
    NSMutableArray *_lrcList;
    NSMutableArray *_lrcTimeList;
    NSString *keyword;
    int currentPage;
    int currentSongIndex;
    int totalPage;
    int currentTimeLength;
    int currentLrcRow;
}


- (instancetype)init {
    if (self = [super init]) {
        _songList = [NSMutableArray array];
        _lrcList = [NSMutableArray array];
        _lrcTimeList = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)songList {
    return _songList;
}

- (NSArray *)lrcList {
    return _lrcList;
}

- (BOOL)hasMore {
    return currentPage < totalPage;
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
    callBack.onError = ^(long status, NSString* responseString){
        if (complete) {
            complete(NO);
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
                currentTimeLength = [result[@"data"][@"timeLength"] intValue];
                complete(YES, result[@"data"][@"url"]);
            }
            else {
                complete(NO, nil);
            }
        }
    };
    
    callBack.onError = ^(long status, NSString* responseString){
        if (complete) {
            complete(NO, nil);
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

- (void)getLrcContentWithComplete:(void (^)(BOOL success))complete {
    APISCallBack *callBack = [[APISCallBack alloc] init];
    callBack.onSuccess = ^(long status, NSString* responseString) {
        NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        BOOL success = [result[@"status"] isEqualToString:@"success"];
        if (success) {
            currentLrcRow = 0;
            NSString *lrcContent = result[@"data"][@"content"];
            NSArray *oriLrcList = [lrcContent componentsSeparatedByString:@"\r\n"];
            [_lrcTimeList removeAllObjects];
            [_lrcList removeAllObjects];
            for (int i = 0; i < [oriLrcList count] - 1; i++) {
                NSString *currentLrcStr = oriLrcList[i];
                [_lrcList addObject:[currentLrcStr substringFromIndex:10]];
                NSRange range;
                range.location = 1;
                range.length = 2;
                float minite = [[currentLrcStr substringWithRange:range] floatValue];
                range.location = 4;
                range.length = 5;
                float second = [[currentLrcStr substringWithRange:range] floatValue];
                [_lrcTimeList addObject:[NSNumber numberWithFloat:minite * 60 + second]];
            }
        }
        complete(success);
    };
    
    SongInfo *songInfo = _songList[currentSongIndex];
    NSDictionary *paras = @{@"name":songInfo.songName,@"hash":songInfo.songHash,@"time":[NSNumber numberWithInt:currentTimeLength]};
    [ApiStoreSDK executeWithURL:kSongLrcRequestUrl
                         method:@"POST"
                         apikey:kAPIStoreKey
                      parameter:[paras mutableCopy]
                       callBack:callBack];
}

- (void)updateLrcPositionWithTime:(float)time
                           isSeek:(BOOL)isSeek
                           notify:(void (^)(int,int))notify{
    if ([_lrcTimeList count] == 0) {
        return;
    }
    int beginRow = currentLrcRow;
    if (isSeek) {
        beginRow = 0;
    }
    for (int i = beginRow; i < [_lrcTimeList count] - 1; i++) {
        if (time > [_lrcTimeList[i + 1] floatValue]) {
            continue;
        }
        else {
            if (i != currentLrcRow) {
                if (notify) {
                    notify(i, currentLrcRow);
                }
                currentLrcRow = i;
            }
            return;
        }
    }
    
}

- (void)getCurrentSingerWithComplecte:(void (^)(BOOL,NSString *))complete{
    APISCallBack *callBack = [[APISCallBack alloc] init];
    callBack.onSuccess = ^(long status, NSString* responseString) {
        
        NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([result[@"status"] isEqualToString:@"success"]) {
            if (complete) {
                complete(YES, result[@"data"][@"image"]);
            }
            return;
        }
        else {
            if (complete != NULL) {
                complete(NO, nil);
            }
        }
    };
    callBack.onError = ^(long status, NSString* responseString){
        if (complete) {
            complete(NO, nil);
        }
    };
    
    SongInfo *songInfo = _songList[currentSongIndex];
    
    [ApiStoreSDK executeWithURL:kSingerInfoRequestUrl
                         method:@"POST"
                         apikey:kAPIStoreKey
                      parameter:[@{@"name":songInfo.singer} mutableCopy]
                       callBack:callBack];

}

@end
