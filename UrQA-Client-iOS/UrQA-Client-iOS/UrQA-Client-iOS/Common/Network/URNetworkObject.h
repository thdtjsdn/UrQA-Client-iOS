//
//  URNetworkObject.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URConfigration.h"
#import "URDefines.h"
#import "URDataObject.h"

typedef enum
{
    ARGUMENT_TYPE_PREVIOUS_INDEX,
    ARGUMENT_TYPE_RESPONSE_VALUE,
    ARGUMENT_TYPE_RESPONSE_ALL_OBJECT
} ARGUMENT_TYPE;

@interface URNextRequestArgument : NSObject

@property (nonatomic, retain) NSString                  *argumentName;
@property (nonatomic, assign) ARGUMENT_TYPE             argumentType;

- (id)initWithArgument:(NSString *)name argumentType:(ARGUMENT_TYPE)type;

@end

@interface URNextRequest : NSObject

@property (nonatomic, assign) Class                     requestClass;
@property (nonatomic, retain) NSArray                   *arguments;     // URNextRequestArgument

@end

@interface URResponse : NSObject

@property (nonatomic, assign) NSInteger                 responseCode;
@property (nonatomic, retain) NSData                    *responseData;

- (id)initWithCode:(NSInteger)code responseData:(NSData *)data;

@end

// Network Process
@interface URNetworkObject : NSObject
{
@protected
    NSMutableArray      *_arguments;
    
@protected
    NSString            *requestURL;
    NSString            *requestMethod;
    NSDictionary        *requestHeader;
    URDataObject        *requestData;
}

@property (nonatomic, getter=_arguments) NSMutableArray *arguments;     // URDataObject

- (BOOL)sendRequest:(void (^)(void))success
            failure:(void (^)(void))failure;
- (BOOL)checkSuccess:(URResponse *)response;

@end

@interface URNetworkObject (URNetworkRequest)

- (NSArray *)nextRequestList;
- (NSInteger)addNextRequest:(URNextRequest *)request;
- (void)removeNextRequestAtIndex:(NSInteger)index;

@end
