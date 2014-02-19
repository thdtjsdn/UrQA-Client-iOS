//
//  URDeviceInformation.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URInformation.h"

#import <UIKit/UIKit.h>

@interface URDeviceInformation : URInformation

@property (nonatomic, readonly) NSInteger       cpuType;
@property (nonatomic, readonly) NSInteger       cpuSubType;
@property (nonatomic, readonly) NSInteger       cpuProcessorCount;
@property (nonatomic, readonly) NSInteger       cpuLogicalProcessorCount;
@property (nonatomic, readonly) double          memoryApp;
@property (nonatomic, readonly) double          memoryFree;
@property (nonatomic, readonly) double          memoryTotal;
@property (nonatomic, readonly) BOOL            isEmulator;
@property (nonatomic, readonly) CGSize          screenSize;

@property (nonatomic, readonly) NSString        *bundleIdentifier;
@property (nonatomic, readonly) NSString        *bundleName;
@property (nonatomic, readonly) NSString        *bundleVersion;
@property (nonatomic, readonly) NSString        *bundleBuildNumber;
@property (nonatomic, readonly) NSString        *machineModel;
@property (nonatomic, readonly) NSString        *osVersion;
@property (nonatomic, readonly) NSString        *osBuildNumber;
@property (nonatomic, readonly) NSString        *language;

@property (nonatomic, readonly) BOOL            isPortrait;
@property (nonatomic, readonly) BOOL            isCalling;
@property (nonatomic, readonly) BOOL            isUseGPS;
@property (nonatomic, readonly) BOOL            isWifiNetworkOn;
@property (nonatomic, readonly) BOOL            isMobileNetworkOn;
@property (nonatomic, readonly) BOOL            isJailbroken;
@property (nonatomic, readonly) BOOL            isAppCracked;

- (BOOL)reloadInformation;

@end
