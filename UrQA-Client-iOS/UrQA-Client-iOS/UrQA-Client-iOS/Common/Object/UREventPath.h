//
//  UREventPath.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDataObject.h"

@interface UREventPath : URDataObject

@property (nonatomic, assign) NSInteger         lineNum;
@property (nonatomic, retain) NSDate            *dateTime;
@property (nonatomic, retain) NSString          *className;
@property (nonatomic, retain) NSString          *methodName;

@end
