//
//  URNetworkObject.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "AFNetworking.h"
#import "URNetworkObject.h"
#import "URDataParser.h"
#import "JSONKit.h"

@interface URNetworkObject()
{
    NSMutableArray          *_nextRequestList;
    URDataParser            *_dataParser;
}

@end

@implementation URNetworkObject

- (id)init
{
    self = [super init];
    if(self)
    {
        _dataParser = [URDataParser parserWithType:@"JSON"];
        
        requestURL = nil;
        requestMethod = @"POST";
        requestHeader = nil;
        requestData = nil;
        
        _arguments = [[NSMutableArray alloc] init];
        _nextRequestList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSInteger)addNextRequest:(URNextRequest *)request
{
    if(![request isKindOfClass:[URNextRequest class]])
        [_nextRequestList addObject:request];
    return [_nextRequestList count] - 1;
}

- (void)removeNextRequestAtIndex:(NSInteger)index
{
    [_nextRequestList removeObjectAtIndex:index];
}

- (BOOL)sendRequest:(void (^)(void))success
            failure:(void (^)(void))failure
{
    NSURL *url = [NSURL URLWithString:requestURL];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url
                                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                        timeoutInterval:10.0f];
    [req setHTTPMethod:requestMethod];
    [req setValue:[NSString stringWithFormat:@"application/%@", @"json"] forHTTPHeaderField:@"Content-Type"];
    if(requestHeader)
    {
        for(int i = 0; i < [requestHeader count]; i ++)
        {
            if([[requestHeader allValues][i] isKindOfClass:[NSString class]] &&
               [[requestHeader allKeys][i] isKindOfClass:[NSString class]])
                [req setValue:[requestHeader allValues][i] forHTTPHeaderField:[requestHeader allKeys][i]];
        }
    }
    [req setHTTPBody:[_dataParser parseObject:requestData]];
    
    void(^__block successProc)(id) = ^(id resObject)
    {
        __block NSInteger successCount = 0;
        __block NSInteger requestCount = [_nextRequestList count];
        
        // 연결된 Request가 완료되었을시 처리
        void(^__block successEvent)(void) = ^{
            successCount ++;
            if(successCount == requestCount)
                success();
        };
        // 연결된 Request가 실패했을때 처리
        void(^__block failedEvent)(void) = ^{
            if(requestCount != -1)
            {
                failure();
                requestCount = -1;
            }
        };
        
        // 연결된 Request 처리
        for(URNextRequest *nReq in _nextRequestList)
        {
            if(![nReq.requestClass isSubclassOfClass:[URNetworkObject class]]) continue;
            
            @try
            {
                // 요청할 Request와 인자값을 저장할 변수를 초기화한다.
                URNetworkObject *nObj = [[nReq.requestClass alloc] init];
                NSMutableArray *nArgu = [[NSMutableArray alloc] init];
                for(URNextRequestArgument *argument in nReq.arguments)
                {
                    NSString *arguName = argument.argumentName;
                    ARGUMENT_TYPE arguType = argument.argumentType;
                    
                    // 이전 요청에서 받은 인자값을 그대로 보낸다.
                    if(arguType == ARGUMENT_TYPE_PREVIOUS_INDEX)
                        [nArgu addObject:_arguments[arguName.integerValue]];
                    
                    // 모든 Response Object를 보낸다.
                    else if(arguType == ARGUMENT_TYPE_RESPONSE_ALL_OBJECT)
                        [nArgu addObject:resObject];
                    
                    // Response Object의 특정 Object만 보낸다.
                    else if(arguType == ARGUMENT_TYPE_RESPONSE_VALUE)
                    {
                        // arguName의 규칙은 다음과 같다.
                        // Ex) [eventpaths][3][datetime]
                        id recObject = resObject;
                        NSArray *componentArray = [arguName componentsSeparatedByString:@"]["];
                        for(NSInteger index = 0; index < [componentArray count]; index ++)
                        {
                            id lastRecObject = recObject;
                            NSString *compStyle = componentArray[index];
                            if(index == 0)
                                compStyle = [compStyle stringByReplacingCharactersInRange:(NSRange){0,1} withString:@""];
                            if(index == [componentArray count] - 1)
                                compStyle = [compStyle stringByReplacingCharactersInRange:(NSRange){compStyle.length-1,1} withString:@""];
                            
                            if(isDigit(compStyle))
                            {
                                if([recObject isKindOfClass:[NSArray class]])
                                    recObject = [(NSArray *)recObject objectAtIndex:compStyle.integerValue];
                                else if([recObject isKindOfClass:[NSDictionary class]])
                                {
                                    recObject = [(NSDictionary *)recObject valueForKey:compStyle];
                                    if(lastRecObject == recObject)
                                        recObject = [(NSDictionary *)recObject allValues][compStyle.integerValue];
                                }
                            }
                            else
                            {
                                if([recObject isKindOfClass:[NSDictionary class]])
                                    recObject = [(NSDictionary *)recObject valueForKey:compStyle];
                            }
                            if(lastRecObject == recObject)
                                [NSException raise:@"EXCEPTION" format:@"PARSING ERROR"];
                        }
                        [nArgu addObject:recObject];
                    }
                }
                
                nObj.arguments = [NSMutableArray arrayWithArray:nArgu];
                [nObj sendRequest:successEvent failure:failedEvent];
            }
            @catch (NSException *exception)
            {
                failedEvent();
                return;
            }
        }
    };
    
    void(^__block currentSuccessProc)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        URLog(@"Server responded with:{\nstatus code: %ld\nheader fields: %@\n}",
              operation.response.statusCode, operation.response.allHeaderFields);
        
        NSData *responseData = nil;
        if([responseObject isKindOfClass:[NSData class]])
            responseData = responseObject;
        
        else if([responseObject isKindOfClass:[NSDictionary class]] ||
                [responseObject isKindOfClass:[NSArray class]])
            responseData = [responseObject JSONData];
        
        else if([responseObject isKindOfClass:[NSString class]])
            responseData = [responseObject dataUsingEncoding:NSUTF8StringEncoding];
        
        if(responseData && [self checkSuccess:[[URResponse alloc] initWithCode:operation.response.statusCode responseData:responseData]])
            successProc(responseObject);
    };
    [[AFHTTPRequestOperationManager manager] HTTPRequestOperationWithRequest:req
                                                                     success:currentSuccessProc
                                                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        URLog(@"Error: %@", error);
        failure();
    }];
    
    return YES;
}

- (BOOL)checkSuccess:(URResponse *)response
{
    if(response.responseCode == 201)
        return YES;
    
    return NO;
}

- (NSArray *)nextRequestList
{
    return [NSArray arrayWithArray:_nextRequestList];
}

@end
