//
//  URCrashReport.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 9..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URCrashReport.h"
#import "URDataObjectMerge.h"

@interface URCrashReport()
{
    NSMutableArray              *_eventPaths;
    NSMutableArray              *_stackTrace;
    NSMutableArray              *_stackCrashed;
    
    URDataObjectMerge           *_mergeObject;
}

@end

@implementation URCrashReport

- (id)init
{
    self = [super init];
    if(self)
    {
        _deviceInfo = nil;
        _eventPaths = [[NSMutableArray alloc] init];
        _stackTrace = [[NSMutableArray alloc] init];
        _stackCrashed = [[NSMutableArray alloc] init];
        _exceptionName = nil;
        _exceptionClass = nil;
        
        _mergeObject = [[URDataObjectMerge alloc] init];
    }
    
    return self;
}

- (id)initWithData:(id)data
{
    return nil;
}

- (NSArray *)eventPaths
{
    return [NSArray arrayWithArray:_eventPaths];
}

- (void)setEventPaths:(NSArray *)eventPaths
{
    _eventPaths = [NSMutableArray arrayWithArray:eventPaths];
}

- (NSArray *)stackTrace
{
    return [NSArray arrayWithArray:_stackTrace];
}

- (void)setStackTrace:(NSArray *)stackTrace
{
    _stackTrace = [NSMutableArray arrayWithArray:stackTrace];
}

- (NSArray *)stackCrashed
{
    return [NSArray arrayWithArray:_stackCrashed];
}

- (void)setStackCrashed:(NSArray *)stackCrashed
{
    _stackCrashed = [NSMutableArray arrayWithArray:stackCrashed];
}

- (id)objectData
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            _machineModel,                  @"device",
            _language,                      @"country",
            _bundleVersion,                 @"appversion",
            _osVersion,                     @"osversion",
            IToS(_isUseGPS),                @"gpson",
            IToS(_isWifiNetworkOn),         @"wifion",
            IToS(_isMobileNetworkOn),       @"mobileon",
            IToS(_screenWidth),             @"scrwidth",
            IToS(_screenHeight),            @"scrheight",
            IToS(_batteryLevel),            @"batterylevel",
            IToS(_diskFree),                @"availsdcard",
            IToS(_isJailbroken),            @"rooted",
            IToS(_memoryApp),               @"appmemmax",
            IToS(_memoryFree),              @"appmemfree",
            IToS(_memoryTotal),             @"appmemtotal",
            _osBuildNumber,                 @"kernelversion",
            FToS(_screenDPI),               @"xdpi",
            FToS(_screenDPI),               @"ydpi",
            IToS(!_isPortrait),             @"scrorientation",
            IToS(_isMemoryWarning),         @"sysmemlow", nil];
}

@end
