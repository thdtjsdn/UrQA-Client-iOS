//
//  URDeviceInfo.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 8..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDataObject.h"

@interface URDeviceInfo : URDataObject

@property (nonatomic, retain) NSString          *machineModel;
@property (nonatomic, retain) NSString          *language;
@property (nonatomic, retain) NSString          *bundleVersion;
@property (nonatomic, retain) NSString          *osVersion;
@property (nonatomic, assign) BOOL              isUseGPS;
@property (nonatomic, assign) BOOL              isWifiNetworkOn;
@property (nonatomic, assign) BOOL              isMobileNetworkOn;
@property (nonatomic, assign) float             screenWidth;
@property (nonatomic, assign) float             screenHeight;
@property (nonatomic, assign) NSInteger         batteryLevel;
@property (nonatomic, assign) double            diskFree;
@property (nonatomic, assign) BOOL              isJailbroken;
@property (nonatomic, assign) double            memoryApp;
@property (nonatomic, assign) double            memoryFree;
@property (nonatomic, assign) double            memoryTotal;
@property (nonatomic, retain) NSString          *osBuildNumber;
@property (nonatomic, assign) float             screenDPI;
@property (nonatomic, assign) BOOL              isPortrait;
@property (nonatomic, assign) BOOL              isMemoryWarning;

@end
