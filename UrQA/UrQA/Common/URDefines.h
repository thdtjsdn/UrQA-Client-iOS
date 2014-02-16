//
//  URDefines.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#if URQA_ENABLE_CONSOLE_LOG
#define URLog(format, args...) NSLog(@"[UrQA] " format, ## args)
#else
#define URLog(format, args...)
#endif

typedef NS_ENUM(NSInteger, URErrorRank)
{
    URErrorRankNothing      = -1,
    URErrorRankUnhandle     = 0,
    URErrorRankNative       = 1,
    URErrorRankCritical     = 2,
    URErrorRankMajor        = 3,
    URErrorRankMinor        = 4
};