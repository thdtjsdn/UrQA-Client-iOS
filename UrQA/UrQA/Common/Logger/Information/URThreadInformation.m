//
//  URThreadInformation.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URThreadInformation.h"

#include <mach/mach_types.h>

@interface URThreadInformation()
{
    NSMutableArray          *_threadInfo;
}

- (BOOL)getThreadInfo:(thread_t *)thread infoTable:(URThreadInfo *)info;

- (void)releaseInformation;

@end

@implementation URThreadInformation

- (id)init
{
    self = [super init];
    if(self)
    {
        _threadInfo = [[NSMutableArray alloc] init];
        [self reloadInformation];
    }
    
    return self;
}

- (void)dealloc
{
    [self releaseInformation];
}

- (void)releaseInformation
{
    for(id info in _threadInfo)
    {
        URThreadInfo *threadInfo = (__bridge URThreadInfo *)info;
        free(threadInfo);
    }
    [_threadInfo removeAllObjects];
}

- (BOOL)reloadInformation
{
    return [self reloadInformation:nil];
}

- (BOOL)reloadInformation:(URThreadInfo *)crashThreadInfo
{
    [self releaseInformation];
    
    thread_act_array_t threads;
    mach_msg_type_number_t thread_count;
    thread_t machThread = mach_thread_self();
    mach_port_deallocate(mach_task_self(), machThread);
    if(task_threads(mach_task_self(), &threads, &thread_count) != KERN_SUCCESS)
    {
        URLog(@"Debug: Fetching thread list failed");
        thread_count = 0;
    }
    for(mach_msg_type_number_t i = 0; i < thread_count; i++)
    {
        if(threads[i] != machThread)
            thread_suspend(threads[i]);
    }
    
    uint32_t threadNumber = 0;
    for(mach_msg_type_number_t i = 0; i < thread_count; i++)
    {
        thread_t thread = threads[i];
        URThreadInfo *threadContext = malloc(sizeof(URThreadInfo));
        
        if(thread == machThread)
        {
            if(crashThreadInfo == NULL)
                continue;
            
            thread = crashThreadInfo->thread;
            memcpy(threadContext, crashThreadInfo, sizeof(URThreadInfo));
        }
        else
        {
            mach_msg_type_number_t stateCount;
            kern_return_t kr;
            
#if defined(__arm64__) || __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
            stateCount = ARM_UNIFIED_THREAD_STATE_COUNT;
            if((kr = thread_get_state(thread, ARM_UNIFIED_THREAD_STATE, (thread_state_t)&threadContext->status, &stateCount)) != KERN_SUCCESS)
            {
                URLog(@"Debug: Fetch of ARM thread state failed with Mach error (%d)", kr);
                return NO;
            }
            
            if(threadContext->status.ash.flavor == ARM_THREAD_STATE64)
                threadContext->registerSize = 8;
            else
                threadContext->registerSize = 4;
#else
            stateCount = ARM_THREAD_STATE_COUNT;
            if((kr = thread_get_state(thread, ARM_THREAD_STATE, (thread_state_t)&threadContext->status.ts_32, &stateCount)) != KERN_SUCCESS)
            {
                URLog(@"Debug: Fetch of ARM thread state failed with Mach error (%d)", kr);
                return NO;
            }
            
            threadContext->status.ash.flavor = ARM_THREAD_STATE32;
            threadContext->status.ash.count = ARM_THREAD_STATE32_COUNT;
            threadContext->registerSize = 4;
#endif
            memset(&threadContext->availableRegisters, 0xFF, sizeof(threadContext->availableRegisters));
        }
        
        if([self getThreadInfo:&thread infoTable:threadContext])
        {
            [_threadInfo addObject:(__bridge id)(threadContext)];
            threadNumber ++;
        }
        else
            free(threadContext);
    }
    
    return YES;
}

- (BOOL)getThreadInfo:(thread_t *)thread infoTable:(URThreadInfo *)info
{
    task_t task = mach_task_self();
    uint32_t depth = 0;
    URThreadInfo prev_frame;
    URThreadInfo frame;
    
    mach_port_mod_refs(mach_task_self(), task, MACH_PORT_RIGHT_SEND, 1);
    memcpy(&frame, info, sizeof(frame));
    
    uint32_t frame_count = 0;
    
    {
        plframe_cursor_frame_reader_t *readers[] = {
            
#if PLCRASH_FEATURE_UNWIND_COMPACT
            plframe_cursor_read_compact_unwind,
#endif
            
#if PLCRASH_FEATURE_UNWIND_DWARF
            plframe_cursor_read_dwarf_unwind,
#endif
            
            plframe_cursor_read_frame_ptr
        };
        
        return plframe_cursor_next_with_readers(cursor, readers, sizeof(readers)/sizeof(readers[0]));
    }
    
    while((ferr = plframe_cursor_next(&cursor)) == PLFRAME_ESUCCESS && frame_count < MAX_THREAD_FRAMES)
    {
        uint32_t frame_size;
        
        /* On the first frame, dump registers for the crashed thread */
        if (frame_count == 0 && crashed) {
            rv += plcrash_writer_write_thread_registers(file, task, &cursor);
        }
        
        /* Fetch the PC value */
        plcrash_greg_t pc = 0;
        if ((ferr = plframe_cursor_get_reg(&cursor, PLCRASH_REG_IP, &pc)) != PLFRAME_ESUCCESS) {
            PLCF_DEBUG("Could not retrieve frame PC register: %s", plframe_strerror(ferr));
            break;
        }
        
        /* Determine the size */
        frame_size = plcrash_writer_write_thread_frame(NULL, writer, pc, image_list, findContext);
        
        rv += plcrash_writer_pack(file, PLCRASH_PROTO_THREAD_FRAMES_ID, PLPROTOBUF_C_TYPE_MESSAGE, &frame_size);
        rv += plcrash_writer_write_thread_frame(file, writer, pc, image_list, findContext);
        frame_count++;
    }
    
    uint32_t size = plcrash_writer_write_thread(NULL, writer, mach_task_self(), thread, thread_number, thr_ctx, image_list, &findContext, crashed);
    
    /* Write message */
    plcrash_writer_pack(file, PLCRASH_PROTO_THREADS_ID, PLPROTOBUF_C_TYPE_MESSAGE, &size);
    plcrash_writer_write_thread(file, writer, mach_task_self(), thread, thread_number, thr_ctx, image_list, &findContext, crashed);
    
    return YES;
}

@end
