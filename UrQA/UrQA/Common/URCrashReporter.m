//
//  URCrashReporter.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URCrashReporter.h"

#import "Logger/URCrashLogger.h"
#import "Eventpath/UREventPath.h"
#import "Handler/URCrashHandler.h"

#import "Handler/URSignalHandler.h"
#import "Handler/URUncaughtHandler.h"

#import <mach/mach.h>
#import <mach/exc.h>

void exceptionCallback(void *context, int tag);
void signalExceptionCallback(siginfo_t *info, ucontext_t *uap);
void machSignalExceptionCallback(siginfo_t *info, exception_type_t exception_type, mach_exception_data_t codes, mach_msg_type_number_t code_count);
void uncaughtExceptionCallback(NSException *exception);

@interface URCrashReporter()
{
    BOOL            _isStarted;
}

@end

@implementation URCrashReporter

- (id)init
{
    self = [super init];
    if(self)
    {
        _crashLogger = [[URCrashLogger alloc] init];
        _eventPath = [[UREventPath alloc] init];
        
        _crashHandler = [[NSMutableArray alloc] init];
#if URQA_ENABLE_SIGNAL_HANDLING
        [_crashHandler addObject:[[URSignalHandler alloc] initWithCallback:exceptionCallback andTag:1]];
#endif
#if URQA_ENABLE_UNCAUGHT_EXCEPTION_HANDLING
        [_crashHandler addObject:[[URUncaughtHandler alloc] initWithCallback:exceptionCallback andTag:2]];
#endif
    }
    
    return self;
}

- (BOOL)start
{
    if(_isStarted)
        return YES;
    
    for(URCrashHandler *handler in _crashHandler)
    {
        if([handler start])
        {
            [self stop];
            return NO;
        }
    }
    
    return YES;
}

- (void)stop
{
    if(!_isStarted)
        return;
    
    for(URCrashHandler *handler in _crashHandler)
        [handler stop];
}

- (void)addEventPath:(NSString *)tag
{
    
}

- (void)sendException:(NSException *)exception andErrorRank:(URErrorRank)errorRank andTag:(NSString *)tag
{
    
}

void exceptionCallback(void *context, int tag)
{
    // signal exception
    if(tag == 1)
    {
        void **array = context;
        if(array[1] == NULL)
            machSignalExceptionCallback(array[0], *(exception_type_t*)array[2], *(mach_exception_data_t*)array[3], *(mach_msg_type_number_t*)array[4]);
        else
            signalExceptionCallback(array[0], array[1]);
    }
    
    // uncaught exception
    else if(tag == 2)
    {
        uncaughtExceptionCallback((__bridge NSException *)context);
    }
}

void signalExceptionCallback(siginfo_t *info, ucontext_t *uap)
{
    
}

void machSignalExceptionCallback(siginfo_t *info, exception_type_t exception_type, mach_exception_data_t codes, mach_msg_type_number_t code_count)
{
    
}

void uncaughtExceptionCallback(NSException *exception)
{
    
}

@end
