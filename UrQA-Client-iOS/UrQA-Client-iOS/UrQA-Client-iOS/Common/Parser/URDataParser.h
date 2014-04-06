//
//  URDataParser.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 8..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDataObject.h"

@interface URDataParser : NSObject

+ (id)parserWithType:(NSString *)parserType;

- (NSData *)parseObject:(URDataObject *)object;
- (id)parseData:(NSData *)data;

@end
