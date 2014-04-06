//
//  URDataObjectMerge.m
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 9..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDataObjectMerge.h"

@implementation URDataObjectMerge

- (id)initWithObject1:(URDataObject *)obj1 object2:(URDataObject *)obj2
{
    self = [super init];
    if(self)
    {
        _object1 = obj1;
        _object2 = obj2;
    }
    
    return self;
}

- (id)initWithData:(id)data
{
    return nil;
}

- (id)objectData
{
    id data1 = [_object1 objectData];
    id data2 = [_object2 objectData];
    
    if(_object1 && _object2)
    {
        if([data1 isKindOfClass:[NSArray class]] && [data2 isKindOfClass:[NSArray class]])
        {
            NSMutableArray *array = [[NSMutableArray alloc] initWithArray:data1];
            [array addObjectsFromArray:data2];
            
            return array;
        }
        else if([data1 isKindOfClass:[NSDictionary class]] && [data2 isKindOfClass:[NSDictionary class]])
        {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:data1];
            [dict addEntriesFromDictionary:data2];
            
            return dict;
        }
        else
        {
            NSArray *array = [NSArray arrayWithObjects:data1, data2, nil];
            
            return array;
        }
    }
    else
        return data2;
}

@end
