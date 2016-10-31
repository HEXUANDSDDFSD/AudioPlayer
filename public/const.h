//
//  const.h
//  LocalStore
//
//  Created by hexuan on 16/8/17.
//  Copyright © 2016年 hexuan. All rights reserved.
//

#ifndef const_h
#define const_h

#define kAppDocumentPath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]
#define kAppCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]
#define kAppTmpPath NSTemporaryDirectory()

#define kAppStatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height

#endif /* const_h */
