//
//  URDataParser.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 8..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDataParser.h"
#import <objc/runtime.h>

@implementation URDataParser

+ (id)parserWithType:(NSString *)parserType
{
    Class classObject = objc_getClass([NSString stringWithFormat:@"UR%@DataParser", parserType].UTF8String);
    if(classObject)
        return [[classObject alloc] init];
    else
        return nil;
}

- (id)init
{
    return nil;
}

- (NSData *)parseObject:(URDataObject *)object
{
    if(object)
    {
        id objectData = [object objectData];
        if([objectData isKindOfClass:[NSString class]])
            return [objectData dataUsingEncoding:NSUTF8StringEncoding];
        else if([objectData isKindOfClass:[NSNumber class]])
            return [[objectData stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (id)parseData:(NSData *)data
{
    return nil;
}

@end
