//
//  URDataObject.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 8..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDataObject.h"

@interface URDataObject()
{
    id              objectData;
}

@end

@implementation URDataObject

- (id)init
{
    self = [super init];
    if(self)
    {
        objectData = nil;
    }
    
    return self;
}

- (id)initWithData:(id)data
{
    if(data && ([data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSArray class]]))
        self = [super init];
    
    if(self)
    {
        objectData = data;
    }
    
    return self;
}

- (id)objectData
{
    return objectData;
}

@end
