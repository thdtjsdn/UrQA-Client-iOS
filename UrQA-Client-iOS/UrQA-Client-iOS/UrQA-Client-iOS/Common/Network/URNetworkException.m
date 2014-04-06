//
//  URNetworkException.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URNetworkException.h"
#import "URDataObjectMerge.h"

@interface URNetworkException()
{
    URDataObject        *_otherObject;
}

- (void)refreshRequestData;

@end

@implementation URNetworkException

- (void)refreshRequestData
{
    [(URDataObjectMerge *)requestData setObject2:[[URDataObject alloc] initWithData:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                     _arguments[0], @"apikey",
                                                                                     _arguments[2], @"rank",
                                                                                     _arguments[3], @"tag", nil]]];
}

- (id)initWithAPIKey:(NSString *)APIKey andErrorReport:(URCrashReport *)report andErrorRank:(URErrorRank)errorRank andTag:(NSString *)tag
{
    self = [super init];
    if(self)
    {
        tag = (!tag) ? @"" : tag;
        
        [_arguments addObject:(_APIKey = APIKey)];
        [_arguments addObject:(_crashReport = report)];
        [_arguments addObject:[NSNumber numberWithInteger:(_errorRank = errorRank)]];
        [_arguments addObject:(_tag = tag)];
        
        requestURL = [NSString stringWithFormat:@"%@%@", __URQA_DOMAIN__, @"/client/send/exception"];
        requestMethod = @"POST";
        requestHeader = nil;
        
        requestData = [[URDataObjectMerge alloc] initWithObject1:_crashReport object2:nil];
        [self refreshRequestData];
    }
    
    return self;
}

- (void)setArguments:(NSMutableArray *)arguments
{
    [super setArguments:arguments];
    _APIKey = arguments[0];
    _crashReport = arguments[1];
    _errorRank = [arguments[2] integerValue];
    _tag = arguments[3];
    
    [(URDataObjectMerge *)requestData setObject1:_crashReport];
    [self refreshRequestData];
}

- (void)setAPIKey:(NSString *)APIKey
{
    _arguments[0] = (_APIKey = APIKey);
    [self refreshRequestData];
}

- (void)setCrashReport:(URCrashReport *)crashReport
{
    _arguments[1] = (_crashReport = crashReport);
    [(URDataObjectMerge *)requestData setObject1:_crashReport];
}

- (void)setErrorRank:(URErrorRank)errorRank
{
    _arguments[2] = [NSNumber numberWithInteger:(_errorRank = errorRank)];
    [self refreshRequestData];
}

- (void)setTag:(NSString *)tag
{
    _arguments[3] = (_tag = tag);
    [self refreshRequestData];
}

- (BOOL)checkSuccess:(URResponse *)response
{
    if(response.responseCode == 201)
        return YES;
    
    return NO;
}

@end
