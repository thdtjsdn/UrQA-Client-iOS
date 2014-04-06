//
//  URCrashReport.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 9..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDataObject.h"
#import "URDeviceInfo.h"
#import "UREventPath.h"

@interface URCrashReport : URDataObject

@property (nonatomic, retain) URDeviceInfo          *deviceInfo;
@property (nonatomic, retain) NSArray               *eventPaths;        // UREventPath
@property (nonatomic, retain) NSArray               *stackTrace;
@property (nonatomic, assign) NSArray               *stackCrashed;      // BOOL
@property (nonatomic, retain) NSString              *exceptionName;
@property (nonatomic, retain) NSString              *exceptionClass;

@end
