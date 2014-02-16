//
//  URUncaughtHandler.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URUncaughtHandler.h"

static URUncaughtHandler            *_uncaughtHandler;

void uncaughtExceptionCallback(NSException *exception);

@implementation URUncaughtHandler

- (id)initWithCallback:(URQACrashCallback)callback andTag:(int)tag
{
    self = [super initWithCallback:callback andTag:tag];
    if(self)
    {
    }
    
    return _uncaughtHandler = self;
}

- (BOOL)start
{
    NSSetUncaughtExceptionHandler(uncaughtExceptionCallback);
    return YES;
}

- (BOOL)stop
{
    NSSetUncaughtExceptionHandler(NULL);
    return YES;
}
                                      
void uncaughtExceptionCallback(NSException *exception)
{
    // Logging
    
    URQACrashCallback callback = [_uncaughtHandler callback];
    callback((__bridge void *)exception, [_uncaughtHandler tag]);
}

@end
