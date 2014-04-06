//
//  AppDelegate.m
//  UrQA-Example
//
//  Created by Kawoou on 2014. 3. 6..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "AppDelegate.h"
#include <asl.h>

@implementation AppDelegate

- (void)logPrint:(NSDate *)theDate
{
    aslmsg q, m;
    NSDictionary *infoDictionary = [NSBundle mainBundle].infoDictionary;
    NSString *productName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    aslclient client = asl_open(productName.UTF8String, "com.apple.console", ASL_OPT_NO_DELAY);
    int i;
    const char *key, *val;
    
    q = asl_new(ASL_TYPE_QUERY);
    asl_set_query(q, ASL_KEY_MSG_ID, "969211", ASL_QUERY_OP_GREATER_EQUAL | ASL_QUERY_OP_NUMERIC);
    asl_set_query(q, ASL_KEY_TIME, [[NSString stringWithFormat:@"%d", (int)[theDate timeIntervalSince1970]] cStringUsingEncoding:NSUTF8StringEncoding], ASL_QUERY_OP_GREATER_EQUAL | ASL_QUERY_OP_NUMERIC);
    
    aslresponse r = asl_search(client, q);
    while (NULL != (m = aslresponse_next(r)))
    {
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        
        for (i = 0; (NULL != (key = asl_key(m, i))); i++)
        {
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];
            
            val = asl_get(m, key);
            
            NSString *string = val?[NSString stringWithUTF8String:val]:@"";
            [tmpDict setObject:string forKey:keyString];
        }
        
        NSLog(@"%@", tmpDict);
    }
    aslresponse_free(r);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDate *theDate = [NSDate date];
    NSLog(@"%@", [NSThread callStackSymbols]);
    NSLog(@"%s %s %d", __PRETTY_FUNCTION__, __func__, __LINE__);
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    if([[NSFileManager defaultManager] fileExistsAtPath:logPath])
    {
        NSLog(@"-------------------\n%@\n-------------------------------------", [NSString stringWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:nil]);
    }
     */

    [self logPrint:theDate];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
