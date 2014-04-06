//
//  URDeviceInformation.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URDeviceManager.h"

#import "URConfigration.h"
#import "URDefines.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import "../../../Framework/Reachability/Reachability.h"

#include <sys/stat.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/mach.h>
#include <mach/mach_host.h>
#include <libkern/OSMemoryNotification.h>

@interface URDeviceManager()
{
    NSBundle        *_bundle;
}

@property (nonatomic, readonly) NSInteger               cpuType;
@property (nonatomic, readonly) NSInteger               cpuSubType;
@property (nonatomic, readonly) NSInteger               cpuProcessorCount;
@property (nonatomic, readonly) NSInteger               cpuLogicalProcessorCount;
@property (nonatomic, readonly) NSInteger               batteryLevel;
@property (nonatomic, readonly) UIDeviceBatteryState    batteryStatus;
@property (nonatomic, readonly) double                  memoryApp;
@property (nonatomic, readonly) double                  memoryFree;
@property (nonatomic, readonly) double                  memoryTotal;
@property (nonatomic, readonly) double                  diskFree;
@property (nonatomic, readonly) double                  diskTotal;
@property (nonatomic, readonly) BOOL                    isEmulator;
@property (nonatomic, readonly) BOOL                    isMemoryWarning;
@property (nonatomic, readonly) CGFloat                 screenDPI;
@property (nonatomic, readonly) CGSize                  screenSize;

@property (nonatomic, readonly) NSString                *bundleIdentifier;
@property (nonatomic, readonly) NSString                *bundleName;
@property (nonatomic, readonly) NSString                *bundleVersion;
@property (nonatomic, readonly) NSString                *bundleBuildNumber;
@property (nonatomic, readonly) NSString                *machineModel;
@property (nonatomic, readonly) NSString                *osVersion;
@property (nonatomic, readonly) NSString                *osBuildNumber;
@property (nonatomic, readonly) NSString                *language;

@property (nonatomic, readonly) BOOL                    isPortrait;
@property (nonatomic, readonly) BOOL                    isCalling;
@property (nonatomic, readonly) BOOL                    isUseGPS;
@property (nonatomic, readonly) BOOL                    isWifiNetworkOn;
@property (nonatomic, readonly) BOOL                    isMobileNetworkOn;
@property (nonatomic, readonly) BOOL                    isJailbroken;
@property (nonatomic, readonly) BOOL                    isAppCracked;

- (BOOL)detectJailbroken;
- (BOOL)detectAppCracked;

- (BOOL)getSystemNumber:(NSString *)name result:(int *)result;
- (NSString *)getSystemString:(NSString *)name;

@end

@implementation URDeviceManager

+ (URDeviceInfo *)createDeviceReport
{
    static URDeviceManager *manager = nil;
    
    // It makes singleton object thread-safe
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[URDeviceManager alloc] init];
    });
    
    URDeviceInfo *device = nil;
    if(manager)
    {
        [manager reloadInformation];
        
        device = [[URDeviceInfo alloc] init];
        device.machineModel = [manager machineModel];
        device.language = [manager language];
        device.bundleVersion = [manager bundleVersion];
        device.osVersion = [manager osVersion];
        device.isUseGPS = [manager isUseGPS];
        device.isWifiNetworkOn = [manager isWifiNetworkOn];
        device.isMobileNetworkOn = [manager isMobileNetworkOn];
        device.screenWidth = [manager screenSize].width;
        device.screenHeight = [manager screenSize].height;
        device.batteryLevel = [manager batteryLevel];
        device.diskFree = [manager diskFree];
        device.isJailbroken = [manager isJailbroken];
        device.memoryApp = [manager memoryApp];
        device.memoryFree = [manager memoryFree];
        device.memoryTotal = [manager memoryTotal];
        device.osBuildNumber = [manager osBuildNumber];
        device.screenDPI = [manager screenDPI];
        device.isPortrait = [manager isPortrait];
        device.isMemoryWarning = [manager isMemoryWarning];
    }
    return device;
}

/*
+ (URDeviceManager *)sharedInstance
{
    static URDeviceManager *manager = nil;
    
    // It makes singleton object thread-safe
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[URDeviceManager alloc] init];
    });
    
    return manager;
}
 */

- (id)init
{
    self = [super init];
    if(self)
    {
        _bundle = [NSBundle mainBundle];
        [self reloadInformation];
    }
    
    return self;
}

- (BOOL)reloadInformation
{
    static id callCenter = nil;
    static id locationManager = nil;
    UIDevice *device = [UIDevice currentDevice];
    
    int retval;
    
    // CPU
    if([self getSystemNumber:@"hw.cputype" result:&retval])
        _cpuType = retval;
    else
        return NO;
    
    if([self getSystemNumber:@"hw.cpusubtype" result:&retval])
        _cpuSubType = retval;
    else
        return NO;
    
    if([self getSystemNumber:@"hw.physicalcpu_max" result:&retval])
        _cpuProcessorCount = retval;
    else
        return NO;
    
    if([self getSystemNumber:@"hw.logicalcpu_max" result:&retval])
        _cpuLogicalProcessorCount = retval;
    else
        return NO;
    
    // Battery
    BOOL lastBatteryMonitoringState = [device isBatteryMonitoringEnabled];
    [device setBatteryMonitoringEnabled:YES];
    
    _batteryLevel = [device batteryLevel] * 100;
    _batteryStatus = [device batteryState];
    
    [device setBatteryMonitoringEnabled:lastBatteryMonitoringState];
    
    // Memory
    mach_port_t host_port;
    struct mach_task_basic_info info;
    mach_msg_type_number_t host_size;
    mach_msg_type_number_t size = sizeof(info);
    vm_size_t pagesize;
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    if(host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        return NO;
    if(task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size) != KERN_SUCCESS)
        return NO;
    
    _memoryApp = info.resident_size / 1048576.0f;
    _memoryFree = vm_stat.free_count * pagesize / 1048576.0f;
    _memoryTotal = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize / 1048576.0f + _memoryFree;
    
    // Disk
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if(dictionary)
    {
        _diskFree = (([[dictionary objectForKey:NSFileSystemFreeSize] unsignedLongLongValue] * 0.0009765625) * 0.0009765625);
        _diskTotal = (([[dictionary objectForKey: NSFileSystemSize] unsignedLongLongValue] * 0.0009765625) * 0.0009765625);
    }
    else
        return NO;
    
    // is Emulator
    _isEmulator = YES;
    if([self getSystemNumber:@"sysctl.proc_native" result:&retval])
    {
        if(retval == 0)
            _isEmulator = YES;
        else
            _isEmulator = NO;
    }
    else
        _isEmulator = NO;
    
    // is Memory warning
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
    {
        @try
        {
            CLANG_IGNORE(-Wdeprecated-declarations)
            switch(OSMemoryNotificationCurrentLevel())
            {
                case OSMemoryNotificationLevelAny:
                case OSMemoryNotificationLevelNormal:
                    _isMemoryWarning = NO;
                    break;
                    
                case OSMemoryNotificationLevelWarning:
                case OSMemoryNotificationLevelUrgent:
                case OSMemoryNotificationLevelCritical:
                    _isMemoryWarning = YES;
                    break;
            }
            CLANG_POP
        }
        @catch (NSException *exception)
        {
            _isMemoryWarning = NO;
        }
    }
    else
        _isMemoryWarning = NO;
    
    // Screen DPI
    float scale = 1;
    if((BOOL)(([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]&&[[UIScreen mainScreen] respondsToSelector:@selector(scale)]&&[[UIScreen mainScreen] scale]>1.0)))
        scale = [[UIScreen mainScreen] scale];
    
    _screenDPI = 160 * scale;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        _screenDPI = 132 * scale;
    else if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        _screenDPI = 163 * scale;
    
    // Screen Size
    _screenSize = [UIScreen mainScreen].bounds.size;
    
    // Bundle
    _bundleIdentifier = [_bundle bundleIdentifier];
    _bundleName = [[_bundle infoDictionary] objectForKey:@"CFBundleDisplayName"];
    _bundleVersion = [[_bundle infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    _bundleBuildNumber = [[_bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if(!_bundleIdentifier)
    {
        const char *progname = getprogname();
        if(!progname)
            return NO;
        
        _bundleIdentifier = [NSString stringWithUTF8String:progname];
    }
    if(!_bundleVersion)
        _bundleVersion = @"";
    
    // Model
    _machineModel = [self getSystemString:@"hw.machine"];
    if(!_machineModel)
        return NO;
    
    // OS Version
    _osVersion = [[UIDevice currentDevice] systemVersion];
    
    // OS Build Number
    _osBuildNumber = [self getSystemString:@"kern.osversion"];
    if(!_osBuildNumber)
        return NO;
    
    // Language
    _language = [[NSLocale currentLocale] objectForKey:@"locale"];;
    
    // Portrait Detect
    _isPortrait = UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation);;
    
    // is Calling
    _isCalling = NO;
    if(NSClassFromString(@"CTCallCenter"))
    {
        if(callCenter)
            callCenter = [[NSClassFromString(@"CTCallCenter") alloc] init];
        
        for(id call in [callCenter performSelector:@selector(currentCalls)])
        {
            if([call performSelector:@selector(callState)] == CTCallStateConnected)
                _isCalling = YES;
        }
    }

    // GPS
    if(NSClassFromString(@"CLLocationManager"))
    {
        if(!locationManager)
            locationManager = [[NSClassFromString(@"CLLocationManager") alloc] init];
        
        CLANG_IGNORE(-Wundeclared-selector)
        _isUseGPS = (BOOL)[locationManager performSelector:@selector(locationServicesEnabled)];
        CLANG_POP
    }
    else
        _isUseGPS = NO;
    
    // Wifi/Mobile Network Detect
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reach currentReachabilityStatus];
    switch(status)
    {
        case NotReachable:
            _isWifiNetworkOn = NO;
            _isMobileNetworkOn = NO;
            break;
            
        case ReachableViaWiFi:
            _isWifiNetworkOn = YES;
            _isMobileNetworkOn = NO;
            break;
            
        case ReachableViaWWAN:
            _isWifiNetworkOn = NO;
            _isMobileNetworkOn = YES;
            break;
            
        default:
            _isWifiNetworkOn = NO;
            _isMobileNetworkOn = NO;
            break;
    }
    
    // Jailbroken
    _isJailbroken = [self detectJailbroken];
    
    // App cracked
    _isAppCracked = [self detectAppCracked];
    
    return YES;
}

- (BOOL)detectJailbroken
{
#if !TARGET_IPHONE_SIMULATOR
    //Apps and System check list
    BOOL isDirectory;
    NSArray *filePathArray = [NSArray arrayWithObjects:
                              @"/Applications/Cydia.app",
                              @"/Applications/FakeCarrier.app",
                              @"/Applications/Icy.app",
                              @"/Applications/IntelliScreen.app",
                              @"/Applications/MxTube.app",
                              @"/Applications/RockApp.app",
                              @"/Applications/SBSettings.app",
                              @"/Applications/WinterBoard.app",
                              @"/private/var/tmp/cydia.log",
                              @"/usr/binsshd",
                              @"/usr/sbinsshd",
                              @"/usr/libexec/sftp-server",
                              @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                              @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
                              @"/Library/MobileSubstrate/MobileSubstrate.dylib",
                              @"/var/log/syslog",
                              @"/bin/bash",
                              @"/bin/sh",
                              @"/etc/ssh/sshd_config",
                              @"/usr/libexec/ssh-keysign",
                              nil];
    NSArray *directoryArray =[NSArray arrayWithObjects:
                              @"/private/var/lib/apt/",
                              @"/private/var/lib/cydia/",
                              @"/private/var/mobileLibrary/SBSettingsThemes/",
                              @"/private/var/stash/",
                              @"/usr/libexec/cydia/",
                              @"/var/cache/apt/",
                              @"/var/lib/apt/",
                              @"/var/lib/cydia/",
                              @"/etc/apt/",
                              nil];
    
    for(NSString *existsPath in filePathArray)
        if([[NSFileManager defaultManager] fileExistsAtPath:existsPath])
            return YES;
    
    for(NSString *existsDirectory in directoryArray)
        if([[NSFileManager defaultManager] fileExistsAtPath:existsDirectory isDirectory:&isDirectory])
            return YES;
    
    // SandBox Integrity Check
    int pid = fork();
    if(!pid)
        exit(0);
    
    if(pid >= 0)
        return YES;
    
    // Symbolic link verification
    struct stat s;
    if(lstat("/Applications", &s) ||
       lstat("/var/stash/Library/Ringstones", &s) ||
       lstat("/var/stash/Library/Wallpaper", &s) ||
       lstat("/var/stash/usr/include", &s) ||
       lstat("/var/stash/usr/libexec", &s) ||
       lstat("/var/stash/usr/share", &s) ||
       lstat("/var/stash/usr/arm-apple-darwin9", &s))
    {
        if(s.st_mode & S_IFLNK)
            return YES;
    }
    
	// Try to write file in private
	NSError *error;
	[[NSString stringWithFormat:@"Jailbreak test string"]
     writeToFile:@"/private/test_jb.txt"
     atomically:YES
     encoding:NSUTF8StringEncoding error:&error];
    
	if(!error)
		return YES;
    else
        [[NSFileManager defaultManager] removeItemAtPath:@"/private/test_jb.txt" error:nil];
#endif
    
	return NO;
}

- (BOOL)detectAppCracked
{
#if !TARGET_IPHONE_SIMULATOR
    NSBundle *bundle = [NSBundle mainBundle];
	NSString* bundlePath = [bundle bundlePath];
	NSFileManager *manager = [NSFileManager defaultManager];
    BOOL fileExists;
    
    //Check to see if the app is running on root
	int root = getgid();
	if(root <= 10)
		return YES;
    
    //Checking for identity signature
	char symCipher[] = { '(', 'H', 'Z', '[', '9', '{', '+', 'k', ',', 'o', 'g', 'U', ':', 'D', 'L', '#', 'S', ')', '!', 'F', '^', 'T', 'u', 'd', 'a', '-', 'A', 'f', 'z', ';', 'b', '\'', 'v', 'm', 'B', '0', 'J', 'c', 'W', 't', '*', '|', 'O', '\\', '7', 'E', '@', 'x', '"', 'X', 'V', 'r', 'n', 'Q', 'y', '>', ']', '$', '%', '_', '/', 'P', 'R', 'K', '}', '?', 'I', '8', 'Y', '=', 'N', '3', '.', 's', '<', 'l', '4', 'w', 'j', 'G', '`', '2', 'i', 'C', '6', 'q', 'M', 'p', '1', '5', '&', 'e', 'h' };
	char csignid[] = "V.NwY2*8YwC.C1";
	for(int i = 0; i < strlen(csignid); i ++)
	{
		for(int j = 0; j < sizeof(symCipher); j ++)
		{
			if(csignid[i] == symCipher[j])
			{
				csignid[i] = j + 0x21;
				break;
			}
		}
	}
	NSString* signIdentity = [[NSString alloc] initWithCString:csignid encoding:NSUTF8StringEncoding];
    
	NSDictionary *info = [bundle infoDictionary];
	if([info objectForKey:signIdentity])
		return YES;
    
    // Check if the below .plist files exists in the app bundle
    fileExists = [manager fileExistsAtPath:([NSString stringWithFormat:@"%@/%@", bundlePath, @"_CodeSignature"])];
	if(!fileExists)
		return YES;
    
    fileExists = [manager fileExistsAtPath:([NSString stringWithFormat:@"%@/%@", bundlePath, @"ResourceRules.plist"])];
	if(!fileExists)
		return YES;
    
    
    fileExists = [manager fileExistsAtPath:([NSString stringWithFormat:@"%@/%@", bundlePath, @"SC_Info"])];
	if(!fileExists)
		return YES;
    
    //Check if the info.plist and exectable files have been modified
    NSDate* pkgInfoModifiedDate = [[manager attributesOfItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PkgInfo"] error:nil] fileModificationDate];
    
	NSString* infoPath = [NSString stringWithFormat:@"%@/%@", bundlePath, @"Info.plist"];
    NSDate* infoModifiedDate = [[manager attributesOfItemAtPath:infoPath error:nil] fileModificationDate];
    if([infoModifiedDate timeIntervalSinceReferenceDate] > [pkgInfoModifiedDate timeIntervalSinceReferenceDate])
		return YES;
    
    NSString* appPathName = [NSString stringWithFormat:@"%@/%@", bundlePath, [[bundle infoDictionary] objectForKey:@"CFBundleDisplayName"]];
	NSDate* appPathNameModifiedDate = [[manager attributesOfItemAtPath:appPathName error:nil] fileModificationDate];
	if([appPathNameModifiedDate timeIntervalSinceReferenceDate] > [pkgInfoModifiedDate timeIntervalSinceReferenceDate])
		return YES;
#endif
    
	return NO;
}

- (BOOL)getSystemNumber:(NSString *)name result:(int *)result
{
    size_t len = sizeof(*result);
    
    if(!sysctlbyname([name UTF8String], result, &len, NULL, 0))
        return false;
    
    return YES;
}

- (NSString *)getSystemString:(NSString *)name
{
    char result[1024];
    size_t result_len = 1024;
    
    if(sysctlbyname([name UTF8String], &result, &result_len, NULL, 0) < 0)
        return nil;
    
    return [NSString stringWithUTF8String:result];
}

@end
