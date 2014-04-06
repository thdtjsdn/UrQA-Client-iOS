//
//  URCrashLogger.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URConfigration.h"
#import "URDefines.h"

@interface URCrashLogger : NSObject

@property (assign) URUncaughtException *uncaughtException;

- (void)logCrashError:(URCrashInfo *)crashError;
- (void)logCrashError:(URCrashInfo *)crashError contextInfo:(ucontext_t *)ucontext;

@end
