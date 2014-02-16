//
//  URCrashReporter.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

@interface URCrashReporter : NSObject

- (void)addEventPath:(NSString *)tag;

- (void)sendException:(NSException *)exception andErrorRank:(URErrorRank)errorRank andTag:(NSString *)tag;

@end
