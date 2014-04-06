//
//  UREventPath.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "UREventPath.h"

@implementation UREventPath

- (id)init
{
    self = [super init];
    if(self)
    {
        _className = nil;
        _methodName = nil;
        _lineNum = -1;
        _dateTime = nil;
    }
    
    return self;
}

- (id)initWithData:(id)data
{
    self = [super initWithData:data];
    if(self)
    {
        _className = [data valueForKey:@"classname"];
        _methodName = [data valueForKey:@"methodname"];
        _lineNum = [[data valueForKey:@"linenum"] integerValue];
        _dateTime = [[[NSDateFormatter alloc] init] dateFromString:[data valueForKey:@"datetime"]];
    }
    
    return self;
}

- (id)objectData
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            _dateTime, "datetime",
            _className, "classname",
            _methodName, "methodname",
            [NSString stringWithFormat:@"%ld", _lineNum], "linenum", nil];
}

@end
