//
//  URDataObjectMerge.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 9..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDataObject.h"

@interface URDataObjectMerge : URDataObject

@property (nonatomic, retain) URDataObject      *object1;
@property (nonatomic, retain) URDataObject      *object2;

- (id)initWithObject1:(URDataObject *)obj1 object2:(URDataObject *)obj2;

@end
