//
//  URDefines.h
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#include <mach/mach.h>

#define CLANG_IGNORE_HELPER0(x) #x
#define CLANG_IGNORE_HELPER1(x) CLANG_IGNORE_HELPER0(clang diagnostic ignored x)
#define CLANG_IGNORE_HELPER2(y) CLANG_IGNORE_HELPER1(#y)

#define CLANG_POP _Pragma("clang diagnostic pop")
#define CLANG_IGNORE(x)\
_Pragma("clang diagnostic push");\
_Pragma(CLANG_IGNORE_HELPER2(x))

#if URQA_ENABLE_CONSOLE_LOG
#define URLog(format, args...) NSLog(@"[UrQA] " format, ## args)
#else
#define URLog(format, args...)
#endif

#define URQA_TERMINATE_MSGH_ID          0xDEADBEEF

static NSString *kURQAException         = @"UrQAException";

typedef void (*URQACrashCallback)(void *context, int tag);

typedef struct
{
    thread_t                        thread;
    size_t                          registerSize;
    uint64_t                        availableRegisters;
    arm_unified_thread_state_t      status;
} URThreadInfo;

typedef struct
{
    task_t task;
    uint32_t depth;
    URThreadInfo prev_frame;
    URThreadInfo frame;
} URCursorInfo;

typedef struct
{
    BOOL isMachSignal;
    struct
    {
        int signo;
        int code;
        void *address;
    } bsdSignal;
    
    struct
    {
        exception_type_t type;
        mach_exception_data_t code;
        mach_msg_type_number_t codeCount;
    } machSignal;
} URCrashInfo;

typedef struct
{
    bool                            hasException;
    char                            *name;
    char                            *reason;
    void                            **callstack;
    size_t                          callstackCount;
} URUncaughtException;

typedef NS_ENUM(NSInteger, URErrorRank)
{
    URErrorRankNothing      = -1,
    URErrorRankUnhandle     = 0,
    URErrorRankNative       = 1,
    URErrorRankCritical     = 2,
    URErrorRankMajor        = 3,
    URErrorRankMinor        = 4
};

typedef NS_ENUM(NSInteger, UR_EXC)
{
    UR_EXC_CANNOT_DETERMINE_PROCESSNAME                 = 0,
    UR_EXC_UNAVAILABLE_BUNDLE_VERSION,
    UR_EXC_COULDNOT_CREATE_DOC_DIR,
    UR_EXC_FAILED_LOAD_CRASH_REPORT,
    UR_EXC_COULDNOT_RETRIVE_,
    UR_EXC_FAILED_FETCH_VM_STATISTICS,
    UR_EXC_COUNT
};
static NSString *UR_EXC_DESC[UR_EXC_COUNT] = {
    @"Can't determine process identifier or process name.",
    @"Bundle version unavailable.",
    @"Could not create documents directory: %@",
    @"Failed to load crash report data: %@",
    @"Could not retrive %@: %s",
    @"Failed to fetch vm statistics: %s"
};