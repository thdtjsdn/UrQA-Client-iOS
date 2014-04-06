//
//  URNetworkExceptionLog.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 7..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URNetworkExceptionLog.h"

@interface URNetworkExceptionLog()
{
    NSArray             *_objects;
}

@end

@implementation URNetworkExceptionLog

- (id)initWithObject:(NSArray *)objects
{
    self = [super init];
    if(self)
    {
        _objects = objects;
    }
    
    return self;
}

- (NSString *)requestMethod
{
    return @"POST";
}

- (NSString *)requestURL
{
    return [NSString stringWithFormat:@"http://urqa.apiary.io/client/send/exception/log/%@", _objects[0]];
}

- (id)requestData
{
    return [NSString stringWithFormat:@""];
}

- (BOOL)isSuccessCheck:(NSString *)responseString andReponseCode:(NSInteger)code
{
    if(code == 200 && [responseString isEqualToString:@"{ ok }"])
        return YES;
    return NO;
}

@end
