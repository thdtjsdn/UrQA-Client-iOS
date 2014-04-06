//
//  URNetworkException.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URNetworkObject.h"
#import "URCrashReport.h"

@interface URNetworkException : URNetworkObject

@property (nonatomic, retain) NSString          *APIKey;
@property (nonatomic, retain) URCrashReport     *crashReport;
@property (nonatomic, assign) URErrorRank       errorRank;
@property (nonatomic, retain) NSString          *tag;

- (id)initWithAPIKey:(NSString *)APIKey andErrorReport:(URCrashReport *)report andErrorRank:(URErrorRank)errorRank andTag:(NSString *)tag;

@end
