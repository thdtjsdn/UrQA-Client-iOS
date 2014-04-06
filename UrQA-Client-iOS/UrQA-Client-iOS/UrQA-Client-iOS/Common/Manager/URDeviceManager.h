//
//  URDeviceInformation.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "URDeviceInfo.h"

@interface URDeviceManager : NSObject

//+ (URDeviceManager *)sharedInstance;
//- (BOOL)reloadInformation;

+ (URDeviceInfo *)createDeviceReport;

@end
