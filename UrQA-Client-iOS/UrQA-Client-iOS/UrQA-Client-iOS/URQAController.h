//
//  UrQA_Client_iOS.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 2. 26..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "Common/URConfigration.h"
#import "Common/URDefines.h"

#define leaveBreadcrumb(_BREADCRUMB)    [URQAController leaveBreadcrumb:__LINE__ label:_BREADCRUMB];
#define URQALog(_EXCEPTION, _TAG)       [URQAController logException:_EXCEPTION withTag:_TAG];

@interface URQAController : NSObject

+ (NSString *)APIKey;
+ (void)setAPIKey:(NSString *)APIKey;

+ (URQAController *)sharedController;
+ (URQAController *)sharedControllerWithAPIKey:(NSString *)APIKey;

+ (BOOL)leaveBreadcrumb:(NSInteger)lineNumber;
+ (BOOL)leaveBreadcrumb:(NSInteger)lineNumber label:(NSString *)breadcrumb;

+ (BOOL)logException:(NSException *)exception;
+ (BOOL)logException:(NSException *)exception withTag:(NSString *)tag;
//+ (BOOL)logException:(NSException *)exception withTag:(NSString *)tag andErrorRank:(URErrorRank *)errorRank;

@end