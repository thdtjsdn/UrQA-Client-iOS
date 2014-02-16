//
//  UrQA.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URQAController.h"
#import "Common/URCrashReporter.h"

static URQAController           *_urqaController;

static URCrashReporter          *_crashReporter;
static NSString                 *_APIKey;

@implementation URQAController

+ (NSString *)APIKey
{
    if(_urqaController)
        return _APIKey;
    
    return nil;
}

+ (URQAController *)sharedController
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _urqaController = [[URQAController alloc] init];
    });
    
    return _urqaController;
}

+ (URQAController *)sharedControllerWithAPIKey:(NSString *)APIKey
{
    [URQAController sharedController];
    _APIKey = APIKey;
    
    return _urqaController;
}

+ (void)leaveBreadcrumb
{
    [_crashReporter addEventPath:nil];
}

+ (void)leaveBreadcrumb:(NSString *)tag
{
    [_crashReporter addEventPath:tag];
}

+ (void)logException:(NSException *)exception
{
    [_crashReporter sendException:exception andErrorRank:URErrorRankCritical andTag:nil];
}

+ (void)logException:(NSException *)exception withTag:(NSString *)tag
{
    [_crashReporter sendException:exception andErrorRank:URErrorRankCritical andTag:tag];
}

+ (void)logException:(NSException *)exception withTag:(NSString *)tag andErrorRank:(URErrorRank)errorRank
{
    [_crashReporter sendException:exception andErrorRank:errorRank andTag:tag];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _APIKey = nil;
        _crashReporter = [[URCrashReporter alloc] init];
    }
    
    return self;
}

@end