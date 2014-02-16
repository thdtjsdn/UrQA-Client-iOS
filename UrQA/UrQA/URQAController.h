//
//  URQAController.h
//  URQAController
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "Common/URConfigration.h"
#import "Common/URDefines.h"

#define URQALog(_EXCEPTION, _TAG) [URQAController logException:_EXCEPTION withTag:_TAG];

@interface URQAController : NSObject

+ (NSString *)APIKey;

+ (URQAController *)sharedController;
+ (URQAController *)sharedControllerWithAPIKey:(NSString *)APIKey;

+ (void)leaveBreadcrumb;
+ (void)leaveBreadcrumb:(NSString *)tag;

+ (void)logException:(NSException *)exception;
+ (void)logException:(NSException *)exception withTag:(NSString *)tag;
+ (void)logException:(NSException *)exception withTag:(NSString *)tag andErrorRank:(URErrorRank)errorRank;

@end
