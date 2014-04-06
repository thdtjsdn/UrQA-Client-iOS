//
//  URNetworkConnect.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URNetworkConnect.h"

@interface URNetworkConnect()

- (void)refreshRequestData;

@end

@implementation URNetworkConnect

- (void)refreshRequestData
{
    requestData = [[URDataObject alloc] initWithData:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      _arguments[0], @"apikey",
                                                      [_arguments[1] bundleVersion], @"appversion", nil]];
}

- (id)initWithAPIKey:(NSString *)APIKey deviceInfo:(URDeviceInfo *)device
{
    self = [super init];
    if(self)
    {
        [_arguments addObject:(_APIKey = APIKey)];
        [_arguments addObject:(_deviceInfo = device)];
        
        requestURL = [NSString stringWithFormat:@"%@%@", __URQA_DOMAIN__, @"/client/connect"];
        requestMethod = @"POST";
        requestHeader = nil;
        [self refreshRequestData];
    }
    
    return self;
}

- (void)setArguments:(NSMutableArray *)arguments
{
    [super setArguments:arguments];
    _APIKey = arguments[0];
    _deviceInfo = arguments[1];
    
    [self refreshRequestData];
}

- (void)setAPIKey:(NSString *)APIKey
{
    _arguments[0] = (_APIKey = APIKey);
    [self refreshRequestData];
}

- (void)setDeviceInfo:(URDeviceInfo *)deviceInfo
{
    _arguments[1] = (_deviceInfo = deviceInfo);
    [self refreshRequestData];
}

- (BOOL)checkSuccess:(URResponse *)response
{
    if(response.responseCode == 201)
        return YES;
    
    return NO;
}

@end
