//
//  URCrashHandler.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URCrashHandler.h"

@interface URCrashHandler()
{
@protected
    BOOL            _isStarted;
}

@end

@implementation URCrashHandler

- (id)init
{
    return nil;
}

- (id)initWithCallback:(URQACrashCallback)callback andTag:(int)tag
{
    self = [super init];
    if(self)
    {
        _callback = callback;
        _tag = tag;
    }
    
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (BOOL)start
{
    if(_isStarted)
        return NO;
    
    return _isStarted = YES;
}

- (BOOL)stop
{
    if(!_isStarted)
        return NO;
    
    _isStarted = NO;
    return YES;
}

@end
