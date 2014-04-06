//
//  EventPathManager.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "UREventPathManager.h"
#import "UREventPath.h"

static const NSInteger kMaxEventPath            = 10;

@interface UREventPathManager()
{
    NSMutableArray          *_eventPaths;
}

@end

@implementation UREventPathManager

+ (UREventPathManager *)sharedInstance
{
    static UREventPathManager *manager = nil;
    
    // It makes singleton object thread-safe
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[UREventPathManager alloc] init];
    });
    
    return manager;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _eventPaths = [[NSMutableArray alloc] initWithCapacity:kMaxEventPath];
    }
    
    return self;
}

- (BOOL)createEventPath:(NSInteger)step lineNumber:(NSInteger)linenum
{
    [self createEventPath:step lineNumber:linenum label:@""];
    return NO;
}

- (BOOL)createEventPath:(NSInteger)step lineNumber:(NSInteger)linenum label:(NSString *)label
{
    NSArray *stackTrace = [NSThread callStackSymbols];
    NSArray *stepArray = [stackTrace[stackTrace.count - step] componentsSeparatedByString:@" "];
    NSMutableArray *stepInfo = [[NSMutableArray alloc] init];
    for(NSString *str in stepArray)
    {
        if(![str isEqualToString:@" "])
            [stepInfo addObject:str];
    }

    NSString *className = @"";
    NSString *methodName = stepInfo[3];
    if([[stepInfo[3] componentsSeparatedByString:@"["] count] >= 2)
    {
        className = [stepInfo[3] componentsSeparatedByString:@"["][1];
        methodName = [stepInfo[4] componentsSeparatedByString:@"]"][0];
    }
    
    UREventPath *eventPath = [[UREventPath alloc] init];
    eventPath.className = className;
    eventPath.methodName = methodName;
    eventPath.lineNum = linenum;
    eventPath.dateTime = [NSDate date];
    
    if([_eventPaths count] >= kMaxEventPath)
        [_eventPaths removeObjectAtIndex:0];
    [_eventPaths addObject:eventPath];
    
    return YES;
}

- (NSArray *)eventPath
{
    return [NSArray arrayWithArray:_eventPaths];
}

- (void)removeAllObjects
{
    [_eventPaths removeAllObjects];
}

- (NSArray *)jsonArrayData
{
    NSMutableArray *arrayData = [[NSMutableArray alloc] initWithCapacity:_eventPaths.count];
    for(UREventPath *eventPath in _eventPaths)
    {
        [arrayData addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              eventPath.dateTime, @"datetime",
                              eventPath.className, @"classname",
                              eventPath.methodName, @"methodname",
                              [NSString stringWithFormat:@"%ld", eventPath.lineNum], @"linenum", nil]];
    }
    
    return [NSArray arrayWithArray:arrayData];
}

@end
