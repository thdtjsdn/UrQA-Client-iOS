//
//  URNetworkConnect.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URNetworkObject.h"
#import "URDeviceInfo.h"

@interface URNetworkConnect : URNetworkObject

@property (nonatomic, retain) NSString          *APIKey;
@property (nonatomic, retain) URDeviceInfo      *deviceInfo;

- (id)initWithAPIKey:(NSString *)APIKey deviceInfo:(URDeviceInfo *)device;

@end
