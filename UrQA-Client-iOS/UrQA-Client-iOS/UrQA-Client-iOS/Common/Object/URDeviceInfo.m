//
//  URDeviceInfo.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 8..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDeviceInfo.h"

@implementation URDeviceInfo

- (id)init
{
    self = [super init];
    if(self)
    {
        _machineModel       = nil;
        _language           = nil;
        _bundleVersion      = nil;
        _osVersion          = nil;
        _isUseGPS           = NO;
        _isWifiNetworkOn    = NO;
        _isMobileNetworkOn  = NO;
        _screenWidth        = -1.0f;
        _screenHeight       = -1.0f;
        _batteryLevel       = -1;
        _diskFree           = -1.0f;
        _isJailbroken       = NO;
        _memoryApp          = -1.0f;
        _memoryFree         = -1.0f;
        _memoryTotal        = -1.0f;
        _osBuildNumber      = nil;
        _screenDPI          = -1.0f;
        _isPortrait         = NO;
        _isMemoryWarning    = NO;
    }
    
    return self;
}

- (id)initWithData:(id)data
{
    self = [super initWithData:data];
    if(self)
    {
        _machineModel       = DInKToS(data, @"device");
        _language           = DInKToS(data, @"country");
        _bundleVersion      = DInKToS(data, @"appversion");
        _osVersion          = DInKToS(data, @"osversion");
        _isUseGPS           = DInKToB(data, @"gpson");
        _isWifiNetworkOn    = DInKToB(data, @"wifion");
        _isMobileNetworkOn  = DInKToB(data, @"mobileon");
        _screenWidth        = DInKToI(data, @"scrwidth");
        _screenHeight       = DInKToI(data, @"scrheight");
        _batteryLevel       = DInKToI(data, @"batterylevel");
        _diskFree           = DInKToI(data, @"availsdcard");
        _isJailbroken       = DInKToB(data, @"rooted");
        _memoryApp          = DInKToI(data, @"appmemmax");
        _memoryFree         = DInKToI(data, @"appmemfree");
        _memoryTotal        = DInKToI(data, @"appmemtotal");
        _osBuildNumber      = DInKToS(data, @"kernelversion");
        _screenDPI          = DInKToF(data, @"xdpi");
        _isPortrait         = !DInKToB(data,@"scrorientation");
        _isMemoryWarning    = DInKToB(data, @"sysmemlow");
    }
    
    return self;
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
