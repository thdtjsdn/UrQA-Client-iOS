//
//  URCrashHandler.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URCrashHandler.h"

@implementation URCrashHandler

- (id)initWithCallback:(URQACrashCallback)callback andTag:(int)tag
{
    self = [super init];
    if(self)
    {
        _callback = callback;
        _tag = tag;
    }
    
    return self;
}

@end
