//
//  EventPathManager.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

@interface UREventPathManager : NSObject

@property (readonly) NSArray            *eventPath;

+ (UREventPathManager *)sharedInstance;

- (BOOL)createEventPath:(NSInteger)step lineNumber:(NSInteger)linenum;
- (BOOL)createEventPath:(NSInteger)step lineNumber:(NSInteger)linenum label:(NSString *)label;
- (void)removeAllObjects;
- (NSArray *)jsonArrayData;

@end
