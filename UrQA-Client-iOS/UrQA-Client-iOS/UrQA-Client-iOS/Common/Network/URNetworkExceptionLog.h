//
//  URNetworkExceptionLog.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 7..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URNetworkObject.h"
#import "../../../Framework/CrashReporter/Source/CrashReporter.h"
#import "../../../Framework/CrashReporter/Source/PLCrashReportTextFormatter.h"

@interface URNetworkExceptionLog : URNetworkObject

- (id)initWithObject:(NSArray *)objects;

@end
