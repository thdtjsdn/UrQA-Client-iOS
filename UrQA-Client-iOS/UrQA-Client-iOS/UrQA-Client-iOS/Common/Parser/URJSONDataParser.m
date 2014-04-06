//
//  URJSONDataParser.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 8..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URJSONDataParser.h"
#import "JSONKit.h"

@implementation URJSONDataParser

- (id)init
{
    self = [super init];
    
    return nil;
}

- (NSData *)parseObject:(URDataObject *)object
{
    if(object)
    {
        id objectData = [object objectData];
        if([objectData isKindOfClass:[NSArray class]] ||
           [objectData isKindOfClass:[NSDictionary class]])
            return [objectData JSONData];
    }
    return [super parseObject:object];
}

- (id)parseData:(NSData *)data
{
    return [data objectFromJSONData];
}

@end
