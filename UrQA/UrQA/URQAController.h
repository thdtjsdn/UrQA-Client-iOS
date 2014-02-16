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

+ (BOOL)leaveBreadcrumb;
+ (BOOL)leaveBreadcrumb:(NSString *)breadcrumb;

+ (BOOL)logException:(NSException *)exception;
+ (BOOL)logException:(NSException *)exception withTag:(NSString *)tag;
+ (BOOL)logException:(NSException *)exception withTag:(NSString *)tag andErrorRank:(URErrorRank *)errorRank;

@end
