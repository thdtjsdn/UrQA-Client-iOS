//
//  URCrashHandler.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URConfigration.h"
#import "URDefines.h"

@interface URCrashHandler : NSObject

@property (nonatomic, assign) URQACrashCallback     callback;
@property (nonatomic, assign) int                   tag;

- (id)initWithCallback:(URQACrashCallback)callback andTag:(int)tag;

- (BOOL)start;
- (BOOL)stop;

@end
