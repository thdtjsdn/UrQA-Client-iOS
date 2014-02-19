//
//  URUncaughtHandler.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URUncaughtHandler.h"

static URUncaughtHandler            *_uncaughtHandler;
static NSUncaughtExceptionHandler   *_oldHandler;

void uncaughtExceptionCallback(NSException *exception);

@implementation URUncaughtHandler

- (id)initWithCallback:(URQACrashCallback)callback andTag:(int)tag
{
    static dispatch_once_t onceToken;
    if(!_uncaughtHandler)
    {
        if(!_uncaughtHandler)
        {
            dispatch_once(&onceToken, ^{
                _uncaughtHandler = [super initWithCallback:callback andTag:tag];
            });
            self = _uncaughtHandler;
            if(self)
            {
                _oldHandler = nil;
            }
        }
    }
    return _uncaughtHandler;
}

- (BOOL)start
{
    if(![super start])
        return NO;
    
    _oldHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(uncaughtExceptionCallback);
    
    return YES;
}

- (BOOL)stop
{
    if(![super stop])
        return NO;
    
    NSSetUncaughtExceptionHandler(_oldHandler);
    _oldHandler = nil;
    
    return YES;
}

void uncaughtExceptionCallback(NSException *exception)
{
    // Logging
    
    URQACrashCallback callback = [_uncaughtHandler callback];
    callback((__bridge void *)exception, [_uncaughtHandler tag]);
    
    _oldHandler(exception);
}

@end
