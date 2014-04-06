//
//  UrQA_Client_iOS.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 2. 26..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URQAController.h"

#import "Common/Manager/URDeviceManager.h"
#import "Common/Manager/UREventPathManager.h"

#import "Common/Network/URNetworkConnect.h"
#import "Common/Network/URNetworkException.h"

#import "../Framework/CrashReporter/Source/CrashReporter.h"
#import "../Framework/CrashReporter/Source/PLCrashReportTextFormatter.h"

@interface URQAController()

@property (nonatomic, retain) NSString      *secretAPIKey;

- (void)processCrashReporter;

@end

static URQAController           *_urqaController;
static UREventPathManager       *_eventPathManager;

#pragma mark - Exception Callback
void postCrashCallback(siginfo_t *info, ucontext_t *uap, void *context)
{
    // This is not async-safe!!! Beware!!!
    if([[PLCrashReporter sharedReporter] hasPendingCrashReport])
    {
        [_urqaController performSelectorOnMainThread:@selector(processCrashReporter)
                                          withObject:nil
                                       waitUntilDone:YES];
    }
}

@implementation URQAController

#pragma mark - Methods
+ (NSString *)APIKey
{
    return [_urqaController performSelector:@selector(secretAPIKey)];
}

+ (void)setAPIKey:(NSString *)APIKey
{
    [_urqaController performSelector:@selector(setSecretAPIKey:) withObject:APIKey];
}

+ (URQAController *)sharedController
{
    // It makes singleton object thread-safe
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _urqaController = [[URQAController alloc] init];
    });
    
    return _urqaController;
}

+ (URQAController *)sharedControllerWithAPIKey:(NSString *)APIKey
{
    URQAController *controller = [URQAController sharedController];
    [controller setSecretAPIKey:APIKey];
    
    return controller;
}

+ (BOOL)leaveBreadcrumb:(NSInteger)lineNumber
{
    [_eventPathManager createEventPath:2 lineNumber:lineNumber];
    return YES;
}

+ (BOOL)leaveBreadcrumb:(NSInteger)lineNumber label:(NSString *)breadcrumb
{
    [_eventPathManager createEventPath:2 lineNumber:lineNumber label:breadcrumb];
    return YES;
}

+ (BOOL)logException:(NSException *)exception
{
    return YES;
}

+ (BOOL)logException:(NSException *)exception withTag:(NSString *)tag
{
    return YES;
}

+ (BOOL)logException:(NSException *)exception withTag:(NSString *)tag andErrorRank:(URErrorRank)errorRank
{
    return YES;
}

- (void)processCrashReporter
{
    URLog(@"Processing crash report");
    
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSError *error = nil;
    
    // Try loading the crash report
    NSData *crashData = [crashReporter loadPendingCrashReportDataAndReturnError:&error];
    if(!crashData)
    {
        URLog(@"Error: Could not load crash report data due to: %@", error);
        [crashReporter purgePendingCrashReport];
        return;
    }
    else
    {
        if(error)
            URLog(@"Warning: %@", error);
    }
    
    PLCrashReport *report = [[PLCrashReport alloc] initWithData:crashData error:&error];
    if(!report)
    {
        URLog(@"Error: Could not parse crash report due to: %@", error);
        [crashReporter purgePendingCrashReport];
        return;
    }
    else
    {
        if(error)
            URLog(@"Warning: %@", error);
    }
    
    URLog(@"Crashed on %@", report.systemInfo.timestamp);
    URLog(@"Crashed with signal %@ (code %@, address=0x%" PRIx64 ")",
          report.signalInfo.name, report.signalInfo.code, report.signalInfo.address);
    
    URNetworkObject *sendInfo = [[[URNetworkException alloc] initWithAPIKey:_secretAPIKey andErrorReport:report andErrorRank:URErrorRankUnhandle andTag:@""] addNextRequest:]
    
    //URNetworkObject *sendInfo = [[[URNetworkException alloc] initWithAPIKey:_secretAPIKey andErrorReport:report andErrorRank:URErrorRankUnhandle andTag:@""] addNextRequest:[URNetworkExceptionLog class] andSendObject:@"idinstance"];
    //if(!sendInfo)
    {
        URLog(@"Error: Could not prepare JSON crash report string.");
        return;
    }
    
    //[[URNetworkManager sharedInstance] sendNetwork:sendInfo];
}

#pragma mark - Initialize
- (id)init
{
    self = [super init];
    if (self)
    {
        _secretAPIKey = nil;
        if(_eventPathManager)
            _eventPathManager = [[UREventPathManager alloc] init];
        
        URNetworkConnect *session = [[URNetworkConnect alloc] initWithAPIKey:_secretAPIKey deviceInfo:_cr
    }
    
    return self;
}

@end
