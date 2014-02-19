//
//  URThreadInformation.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URInformation.h"

#import "URConfigration.h"
#import "URDefines.h"

@interface URThreadInformation : URInformation

@property (readonly) NSArray            *threadInfo;

- (BOOL)reloadInformation;
- (BOOL)reloadInformation:(URThreadInfo *)crashThreadInfo;

@end
