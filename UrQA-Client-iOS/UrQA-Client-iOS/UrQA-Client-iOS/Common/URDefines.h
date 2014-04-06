//
//  URDefines.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#define CLANG_IGNORE_HELPER0(x) #x
#define CLANG_IGNORE_HELPER1(x) CLANG_IGNORE_HELPER0(clang diagnostic ignored x)
#define CLANG_IGNORE_HELPER2(y) CLANG_IGNORE_HELPER1(#y)

#define CLANG_POP _Pragma("clang diagnostic pop")
#define CLANG_IGNORE(x)\
_Pragma("clang diagnostic push");\
_Pragma(CLANG_IGNORE_HELPER2(x))

#define __URQA_DOMAIN__         @"http://urqa.apiary.io/"

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

bool isDigit(NSString* testString)
{
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange nond = [testString rangeOfCharacterFromSet:nonDigits];
    if (NSNotFound == nond.location)
        return YES;
    
    return NO;
}