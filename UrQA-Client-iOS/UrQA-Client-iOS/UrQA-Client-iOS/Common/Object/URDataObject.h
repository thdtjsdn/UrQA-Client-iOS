//
//  URDataObject.h
//  UrQA-Client-iOS
//
//  Created by Kawoou on 2014. 3. 8..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#define IToS(x)         ([NSString stringWithFormat:@"%ld", (NSInteger)(x)])
#define FToS(x)         ([NSString stringWithFormat:@"%lf", (float)(x)])
#define DToS(x)         ([NSString stringWithFormat:@"%f", (double)(x)])
#define DInKToS(d,k)    ([d valueForKey:k])
#define DInKToI(d,k)    ([DInKToS(d,k) integerValue])
#define DInKToF(d,k)    ([DInKToS(d,k) floatValue])
#define DInKToD(d,k)    ([DInKToS(d,k) doubleValue])
#define DInKToB(d,k)    (DInKToI(d,k) != 0)


@interface URDataObject : NSObject

- (id)init;
- (id)initWithData:(id)data;        // NSArray or NSDictionary
- (id)objectData;                   // NSArray or NSDictionary

@end
