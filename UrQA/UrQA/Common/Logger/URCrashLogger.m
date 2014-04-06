//
//  URCrashLogger.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URCrashLogger.h"

@interface URCrashLogger()
{
    URCursorInfo            _cursorInfo;
    URThreadInfo            *_threadInfo;
    URUncaughtException     *_uncaughtException;
}

- (BOOL)loadThreadInfo;
- (uint64_t)threadStateGetReg:(URThreadInfo *)ts registerNumber:(uint32_t)regnum;

@end

@implementation URCrashLogger

- (id)init
{
    self = [super init];
    if(self)
    {
        _threadInfo = NULL;
        _uncaughtException = NULL;
    }
    
    return self;
}

- (void)dealloc
{
    if(_threadInfo)
        free(_threadInfo);
    
    if(_uncaughtException)
        free(_uncaughtException);
}

- (URUncaughtException *)uncaughtException
{
    return _uncaughtException;
}

- (void)setUncaughtException:(URUncaughtException *)uncaughtException
{
    if(_uncaughtException)
        free(_uncaughtException);
    
    _uncaughtException = uncaughtException;
}

- (BOOL)loadThreadInfo
{
    thread_act_array_t threads;
    mach_msg_type_number_t threadCount;
    
    thread_t currentThread = mach_thread_self();
    mach_port_deallocate(mach_task_self(), currentThread);
    
    if(task_threads(mach_task_self(), &threads, &threadCount) != KERN_SUCCESS)
    {
        threadCount = 0;
        return NO;
    }
    
    for(mach_msg_type_number_t i = 0; i < threadCount; i ++)
    {
        if(threads[i] != currentThread)
            thread_suspend(threads[i]);
    }
    
    uint32_t thread_number = 0;
    for(mach_msg_type_number_t i = 0; i < threadCount; i ++)
    {
        thread_t thread = threads[i];
        uint32_t size;
        
        if(currentThread == thread)
        {
            if(_threadInfo == NULL)
                continue;
        }
        
        _cursorInfo.depth = 0;
        _cursorInfo.task = mach_task_self();
        mach_port_mod_refs(mach_task_self(), _cursorInfo.task, MACH_PORT_RIGHT_SEND, 1);
        memcpy(&_cursorInfo.frame, _threadInfo, sizeof(_cursorInfo.frame));
        
        uint32_t frameCount = 0;
        while(1)
        {
            if(_cursorInfo.depth != 0)
            {
                uint64_t fp;
                bool x64 = _cursorInfo.frame.registerSize == sizeof(uint64_t);
                union {
                    uint64_t greg64[2];
                    uint32_t greg32[2];
                } regs;
                void *dest;
                size_t len;
                
                URThreadInfo *prev_frame = NULL;
                if(_cursorInfo.depth >= 2)
                    prev_frame = &_cursorInfo.prev_frame;
                
                if(x64)
                {
                    dest = regs.greg64;
                    len = sizeof(regs.greg64);
                }
                else
                {
                    dest = regs.greg32;
                    len = sizeof(regs.greg32);
                }
                
                if((_cursorInfo.frame.availableRegisters & (1ULL << 1)) == 0)
                {
                    URLog("Debug: The frame pointer is unavailable, can't read saved register.");
                    break;
                }
                if((fp = [self threadStateGetReg:&_cursorInfo.frame registerNumber:1]) == 0x0)
                    break;
                
                if(prev_frame && (prev_frame->availableRegisters & (1ULL << 1)) != 0)
                {
                    uint64_t prev_fp = [self threadStateGetReg:prev_frame registerNumber:1];
                    if(fp < prev_fp)
                    {
                        URLog("Debug: Stack growing in wrong direction, terminating stack walk");
                        break;
                    }
                }
                
                uint64_t new_fp;
                uint64_t new_pc;
                kern_return_t kr;
                
                vm_size_t read_size = len;
                if((kr = vm_read_overwrite(_cursorInfo.task, (vm_address_t)fp, len, (pointer_t)dest, &read_size)) != KERN_SUCCESS)
                {
                    URLog("Debug: Failed to read frame: %d", kr);
                    break;
                }
                
                if(x64)
                {
                    new_fp = regs.greg64[0];
                    new_pc = regs.greg64[1];
                }
                else
                {
                    new_fp = regs.greg32[0];
                    new_pc = regs.greg32[1];
                }
                
                URThreadInfo frame;
                frame = _cursorInfo.frame;
                
                frame.availableRegisters = 0x0;
                [self threadStateSetReg:&frame registerNumber:1 grepNumber:new_fp];
                [self threadStateSetReg:&frame registerNumber:0 grepNumber:new_pc];
                
                if((frame.availableRegisters & (1ULL << 0)) == 0)
                {
                    URLog("Debug: Missing expected IP value in successfully read frame");
                    break;
                }
                uint64_t ip = [self threadStateGetReg:&frame registerNumber:0];
                if(ip <= PAGE_SIZE)
                    break;
                
                _cursorInfo.prev_frame = _cursorInfo.frame;
                _cursorInfo.frame = frame;
            }
            _cursorInfo.depth ++;
            
            if(frameCount >= 512) break;
            
            uint32_t frameSize;
            if(frameCount == 0)
            {
                // _cursorInfo.frame.availableRegisters Logging
            }
            
            
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
        
        /* Determine the size */
        size = plcrash_writer_write_thread(NULL, writer, mach_task_self(), thread, thread_number, thr_ctx, image_list, &findContext, crashed);
        
        /* Write message */
        plcrash_writer_pack(file, PLCRASH_PROTO_THREADS_ID, PLPROTOBUF_C_TYPE_MESSAGE, &size);
        plcrash_writer_write_thread(file, writer, mach_task_self(), thread, thread_number, thr_ctx, image_list, &findContext, crashed);
        
        thread_number++;
    }
    
    return YES;
}

#define RETGEN(name, type, ts) {\
    return (ts->status. type . __ ## name); \
}
#define SETGEN(name, type, ts, regnum, value) {\
    ts->availableRegisters |= 1ULL << regnum; \
    (ts->status. type . __ ## name) = value; \
    break; \
}
- (void)threadStateSetReg:(URThreadInfo *)ts registerNumber:(uint32_t)regnum grepNumber:(uint64_t)reg
{
    if(ts->status.ash.flavor == ARM_THREAD_STATE32)
    {
        switch(regnum)
        {
            case 3:
                SETGEN(r[0], ts_32, ts, regnum, reg);
                
            case 4:
                SETGEN(r[1], ts_32, ts, regnum, reg);
                
            case 5:
                SETGEN(r[2], ts_32, ts, regnum, reg);
                
            case 6:
                SETGEN(r[3], ts_32, ts, regnum, reg);
                
            case 7:
                SETGEN(r[4], ts_32, ts, regnum, reg);
                
            case 8:
                SETGEN(r[5], ts_32, ts, regnum, reg);
                
            case 9:
                SETGEN(r[6], ts_32, ts, regnum, reg);
                
            case 1:
                SETGEN(r[7], ts_32, ts, regnum, reg);
                
            case 10:
                SETGEN(r[8], ts_32, ts, regnum, reg);
                
            case 11:
                SETGEN(r[9], ts_32, ts, regnum, reg);
                
            case 12:
                SETGEN(r[10], ts_32, ts, regnum, reg);
                
            case 13:
                SETGEN(r[11], ts_32, ts, regnum, reg);
                
            case 14:
                SETGEN(r[12], ts_32, ts, regnum, reg);
                
            case 2:
                SETGEN(sp, ts_32, ts, regnum, reg);
                
            case 15:
                SETGEN(lr, ts_32, ts, regnum, reg);
                
            case 0:
                SETGEN(pc, ts_32, ts, regnum, reg);
                
            case 16:
                SETGEN(cpsr, ts_32, ts, regnum, reg);
                
            default:
                __builtin_trap();
        }
    }
    else
    {
        switch(regnum)
        {
            case 3:
                SETGEN(x[0], ts_64, ts, regnum, reg);
                
            case 4:
                SETGEN(x[1], ts_64, ts, regnum, reg);
                
            case 5:
                SETGEN(x[2], ts_64, ts, regnum, reg);
                
            case 6:
                SETGEN(x[3], ts_64, ts, regnum, reg);
                
            case 7:
                SETGEN(x[4], ts_64, ts, regnum, reg);
                
            case 8:
                SETGEN(x[5], ts_64, ts, regnum, reg);
                
            case 9:
                SETGEN(x[6], ts_64, ts, regnum, reg);
                
            case 10:
                SETGEN(x[7], ts_64, ts, regnum, reg);
                
            case 11:
                SETGEN(x[8], ts_64, ts, regnum, reg);
                
            case 12:
                SETGEN(x[9], ts_64, ts, regnum, reg);
                
            case 13:
                SETGEN(x[10], ts_64, ts, regnum, reg);
                
            case 14:
                SETGEN(x[11], ts_64, ts, regnum, reg);
                
            case 15:
                SETGEN(x[12], ts_64, ts, regnum, reg);
                
            case 16:
                SETGEN(x[13], ts_64, ts, regnum, reg);
                
            case 17:
                SETGEN(x[14], ts_64, ts, regnum, reg);
                
            case 18:
                SETGEN(x[15], ts_64, ts, regnum, reg);
                
            case 19:
                SETGEN(x[16], ts_64, ts, regnum, reg);
                
            case 20:
                SETGEN(x[17], ts_64, ts, regnum, reg);
                
            case 21:
                SETGEN(x[18], ts_64, ts, regnum, reg);
                
            case 22:
                SETGEN(x[19], ts_64, ts, regnum, reg);
                
            case 23:
                SETGEN(x[20], ts_64, ts, regnum, reg);
                
            case 24:
                SETGEN(x[21], ts_64, ts, regnum, reg);
                
            case 25:
                SETGEN(x[22], ts_64, ts, regnum, reg);
                
            case 26:
                SETGEN(x[23], ts_64, ts, regnum, reg);
                
            case 27:
                SETGEN(x[24], ts_64, ts, regnum, reg);
                
            case 28:
                SETGEN(x[25], ts_64, ts, regnum, reg);
                
            case 29:
                SETGEN(x[26], ts_64, ts, regnum, reg);
                
            case 30:
                SETGEN(x[27], ts_64, ts, regnum, reg);
                
            case 31:
                SETGEN(x[28], ts_64, ts, regnum, reg);
                
            case 1:
                SETGEN(fp, ts_64, ts, regnum, reg);
                
            case 2:
                SETGEN(sp, ts_64, ts, regnum, reg);
                
            case 32:
                SETGEN(lr, ts_64, ts, regnum, reg);
                
            case 0:
                SETGEN(pc, ts_64, ts, regnum, reg);
                
            case 33:
                SETGEN(cpsr, ts_64, ts, regnum, reg);
                
            default:
                __builtin_trap();
        }
    }
}

- (uint64_t)threadStateGetReg:(URThreadInfo *)ts registerNumber:(uint32_t)regnum
{
    if(ts->status.ash.flavor == ARM_THREAD_STATE32)
    {
        switch(regnum)
        {
            case 3:
                RETGEN(r[0], ts_32, ts);
                
            case 4:
                RETGEN(r[1], ts_32, ts);
                
            case 5:
                RETGEN(r[2], ts_32, ts);
                
            case 6:
                RETGEN(r[3], ts_32, ts);
                
            case 7:
                RETGEN(r[4], ts_32, ts);
                
            case 8:
                RETGEN(r[5], ts_32, ts);
                
            case 9:
                RETGEN(r[6], ts_32, ts);
                
            case 1:
                RETGEN(r[7], ts_32, ts);
                
            case 10:
                RETGEN(r[8], ts_32, ts);
                
            case 11:
                RETGEN(r[9], ts_32, ts);
                
            case 12:
                RETGEN(r[10], ts_32, ts);
                
            case 13:
                RETGEN(r[11], ts_32, ts);
                
            case 14:
                RETGEN(r[12], ts_32, ts);
                
            case 2:
                RETGEN(sp, ts_32, ts);
                
            case 15:
                RETGEN(lr, ts_32, ts);
                
            case 0:
                RETGEN(pc, ts_32, ts);
                
            case 16:
                RETGEN(cpsr, ts_32, ts);
                
            default:
                __builtin_trap();
        }
    }
    else
    {
        switch(regnum)
        {
            case 3:
                RETGEN(x[0], ts_64, ts);
                
            case 4:
                RETGEN(x[1], ts_64, ts);
                
            case 5:
                RETGEN(x[2], ts_64, ts);
                
            case 6:
                RETGEN(x[3], ts_64, ts);
                
            case 7:
                RETGEN(x[4], ts_64, ts);
                
            case 8:
                RETGEN(x[5], ts_64, ts);
                
            case 9:
                RETGEN(x[6], ts_64, ts);
                
            case 10:
                RETGEN(x[7], ts_64, ts);
                
            case 11:
                RETGEN(x[8], ts_64, ts);
                
            case 12:
                RETGEN(x[9], ts_64, ts);
                
            case 13:
                RETGEN(x[10], ts_64, ts);
                
            case 14:
                RETGEN(x[11], ts_64, ts);
                
            case 15:
                RETGEN(x[12], ts_64, ts);
                
            case 16:
                RETGEN(x[13], ts_64, ts);
                
            case 17:
                RETGEN(x[14], ts_64, ts);
                
            case 18:
                RETGEN(x[15], ts_64, ts);
                
            case 19:
                RETGEN(x[16], ts_64, ts);
                
            case 20:
                RETGEN(x[17], ts_64, ts);
                
            case 21:
                RETGEN(x[18], ts_64, ts);
                
            case 22:
                RETGEN(x[19], ts_64, ts);
                
            case 23:
                RETGEN(x[20], ts_64, ts);
                
            case 24:
                RETGEN(x[21], ts_64, ts);
                
            case 25:
                RETGEN(x[22], ts_64, ts);
                
            case 26:
                RETGEN(x[23], ts_64, ts);
                
            case 27:
                RETGEN(x[24], ts_64, ts);
                
            case 28:
                RETGEN(x[25], ts_64, ts);
                
            case 29:
                RETGEN(x[26], ts_64, ts);
                
            case 30:
                RETGEN(x[27], ts_64, ts);
                
            case 31:
                RETGEN(x[28], ts_64, ts);
                
            case 1:
                RETGEN(fp, ts_64, ts);
                
            case 2:
                RETGEN(sp, ts_64, ts);
                
            case 32:
                RETGEN(lr, ts_64, ts);
                
            case 0:
                RETGEN(pc, ts_64, ts);
                
            case 33:
                RETGEN(cpsr, ts_64, ts);
                
            default:
                __builtin_trap();
        }
    }
    return 0;
}

- (void)logCrashError:(URCrashInfo *)crashError
{
    
}

- (void)logCrashError:(URCrashInfo *)crashError contextInfo:(ucontext_t *)ucontext
{
    _threadInfo = malloc(sizeof(URThreadInfo));
    memset(_threadInfo, 0, sizeof(URThreadInfo));
    
#if defined(__LP64__)
    _threadInfo->status.ash.flavor = ARM_THREAD_STATE64;
    _threadInfo->status.ash.count = ARM_THREAD_STATE64_COUNT;
    _threadInfo->registerSize = 8;
    
    memcpy(&_threadInfo->status.ts_64, &ucontext->uc_mcontext->__ss, sizeof(_threadInfo->status.ts_64));
#else
    _threadInfo->status.ash.flavor = ARM_THREAD_STATE32;
    _threadInfo->status.ash.count = ARM_THREAD_STATE32_COUNT;
    _threadInfo->registerSize = 4;
    
    memcpy(&_threadInfo->status.ts_32, &ucontext->uc_mcontext->__ss, sizeof(_threadInfo->status.ts_32));
#endif
    
    memset(&_threadInfo->availableRegisters, 0xFF, sizeof(_threadInfo->availableRegisters));
}

@end
