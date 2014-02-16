//
//  URCrashReporter.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URConfigration.h"
#import "URDefines.h"

@class URCrashLogger;
@class UREventPath;
@interface URCrashReporter : NSObject
{
@private
    URCrashLogger           *_crashLogger;
    UREventPath             *_eventPath;
    
    NSMutableArray          *_crashHandler;
}

- (BOOL)start;
- (void)stop;

- (void)addEventPath:(NSString *)tag;
- (void)sendException:(NSException *)exception andErrorRank:(URErrorRank)errorRank andTag:(NSString *)tag;

@end
