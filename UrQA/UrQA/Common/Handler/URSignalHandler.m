//
//  URSignalHandler.m
//  UrQA
//
//  Created by Kawoou on 2014. 2. 16..
//  Copyright (c) 2014년 Kawoou. All rights reserved.
//

#import "URSignalHandler.h"

#import <mach/mach.h>
#import <mach/exc.h>
#import <libkern/OSAtomic.h>
#import <sys/sysctl.h>
#import <signal.h>
#import <pthread.h>

static URSignalHandler          *_signalHandler;

static thread_t                 _machServerThread;
static mach_port_t              _machServerPort;
static mach_port_t              _machNotifyPort;
static mach_port_t              _machPortSet;
static pthread_mutex_t          _machServerLock;
static pthread_cond_t           _machServerCond;
static uint32_t                 _machServerShouldStop;
static bool                     _machServerStopDone;

static exception_mask_t         _prevMasks[EXC_TYPES_COUNT];
static mach_msg_type_number_t   _prevCount;
static mach_port_t              _prevPorts[EXC_TYPES_COUNT];
static exception_behavior_t     _prevBehaviors[EXC_TYPES_COUNT];
static thread_state_flavor_t    _prevFlavors[EXC_TYPES_COUNT];

void sigabrtCallback(int, siginfo_t *, ucontext_t *);
kern_return_t machExceptionCallback(task_t, thread_t, exception_type_t, mach_exception_data_t, mach_msg_type_number_t);
kern_return_t machExceptionForward(task_t, thread_t, exception_type_t, mach_exception_data_t, mach_msg_type_number_t);
bool machExceptionGetSiginfo(exception_type_t, mach_exception_data_t, mach_msg_type_number_t, cpu_type_t, siginfo_t *);
void *exceptionServerThread(void *arg);

@interface URSignalHandler()
{
    stack_t                 _signalStack;
    struct sigaction        *_oldSignalAction;
}

- (BOOL)registerHandlerWithSIGABRT;
- (BOOL)registerHandlerInMachExceptionServer;

@end

@implementation URSignalHandler

- (id)initWithCallback:(URQACrashCallback)callback andTag:(int)tag
{
    static dispatch_once_t onceToken;
    if(!_signalHandler)
    {
        if(!_signalHandler)
        {
            dispatch_once(&onceToken, ^{
                _signalHandler = [super initWithCallback:callback andTag:tag];
            });
            
            self = _signalHandler;
            if(self)
            {
                _signalStack.ss_size = MAX(MINSIGSTKSZ, 64 * 1024);
                _signalStack.ss_sp = malloc(_signalStack.ss_size);
                _signalStack.ss_flags = 0;
                
                if(!_signalStack.ss_sp)
                    return nil;
                
                _machServerThread = MACH_PORT_NULL;
                _machServerPort = MACH_PORT_NULL;
                _machNotifyPort = MACH_PORT_NULL;
                _machPortSet = MACH_PORT_NULL;
            }
        }
    }
    return _signalHandler;
}

- (BOOL)registerHandlerWithSIGABRT
{
    static pthread_mutex_t registerHandlers = PTHREAD_MUTEX_INITIALIZER;
    pthread_mutex_lock(&registerHandlers);
    
    struct sigaction sa;
    struct sigaction sa_prev;
    
    if(sigaltstack(&_signalStack, 0) < 0)
    {
        URLog(@"ERROR: Couldn't initialize alternative signal stack!");
        return NO;
    }
    
    memset(&sa, 0, sizeof(sa));
    sa.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sa.sa_mask = 0, 0;
    sa.sa_sigaction = &sigabrtCallback;
    
    if(sigaction(SIGABRT, &sa, &sa_prev) != 0)
    {
        URLog(@"ERROR: Failed to register signal handler! (%d)", errno);
        return NO;
    }
    _oldSignalAction = &sa_prev;
    pthread_mutex_unlock(&registerHandlers);
    
    return YES;
}

- (BOOL)registerHandlerInMachExceptionServer
{
    exception_mask_t exc_mask = EXC_MASK_BAD_ACCESS | EXC_MASK_BAD_INSTRUCTION | EXC_MASK_ARITHMETIC | EXC_MASK_SOFTWARE | EXC_MASK_BREAKPOINT;
#ifdef EXC_MASK_GUARD
    {
        char result[1024];
        size_t result_len = 0;
        int ret;
        NSString *resultString;
        if ((ret = sysctlbyname([@"kern.osrelease" UTF8String], &result, &result_len, NULL, 0)) != -1)
            resultString = [[NSString alloc] initWithBytesNoCopy:result length:strlen(result) encoding:NSUTF8StringEncoding freeWhenDone:YES];
        if(ret != -1)
        {
            NSScanner *scanner = [NSScanner scannerWithString:resultString];
            NSInteger majorVersion;
            if ([scanner scanInteger: (NSInteger *) &majorVersion])
            {
                if (majorVersion >= 13)
                    /* Process accessed a guarded file descriptor. See also: https://devforums.apple.com/message/713907#713907 */
                    exc_mask |= EXC_MASK_GUARD;
            }
        }
    }
#endif
    
    pthread_attr_t attr;
    pthread_t thr;
    kern_return_t kr;
    
    // Initialize
    if(pthread_mutex_init(&_machServerLock, NULL) != 0)
    {
        URLog(@"Error: Mutex initialization failed (%d)", errno);
        return NO;
    }
    if(pthread_cond_init(&_machServerCond, NULL) != 0)
    {
        URLog(@"Error: Condition initialization failed (%d)", errno);
        
        pthread_mutex_destroy(&_machServerLock);
        return NO;
    }
    
    // Mach port
    if((kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &_machServerPort)) != KERN_SUCCESS)
    {
        URLog(@"Error: Failed to allocate exception server's port (%d)", kr);
        return NO;
    }
    if((kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &_machNotifyPort)) != KERN_SUCCESS)
    {
        URLog(@"Error: Failed to allocate exception server's port (%d)", kr);
        return NO;
    }
    if((kr = mach_port_insert_right(mach_task_self(), _machNotifyPort, _machNotifyPort, MACH_MSG_TYPE_MAKE_SEND)) != KERN_SUCCESS)
    {
        URLog(@"Error: Failed to add send right to exception server's port (%d)", kr);
        return NO;
    }
    
    mach_port_t prev_notify_port;
    if((kr = mach_port_request_notification(mach_task_self(), _machServerPort, MACH_NOTIFY_NO_SENDERS, 1, _machNotifyPort, MACH_MSG_TYPE_MAKE_SEND_ONCE, &prev_notify_port)) != KERN_SUCCESS)
    {
        URLog(@"Error: Failed to request MACH_NOTIFY_NO_SENDERS on the exception server's port (%d)", kr);
        return NO;
    }
    
    if((kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_PORT_SET, &_machPortSet)) != KERN_SUCCESS)
    {
        URLog(@"Error: Failed to allocate exception server's port set (%d)", kr);
        return NO;
    }
    
    if((kr = mach_port_move_member(mach_task_self(), _machServerPort, _machPortSet)) != KERN_SUCCESS)
    {
        URLog(@"Error: Failed to add exception server port to port set (%d)", kr);
        return NO;
    }
    if((kr = mach_port_move_member(mach_task_self(), _machNotifyPort, _machPortSet)) != KERN_SUCCESS)
    {
        URLog(@"Error: Failed to add exception server notify port to port set (%d)", kr);
        return NO;
    }
    
    // Server thread
    if(pthread_attr_init(&attr) != 0)
    {
        URLog(@"Error: Failed to initialize pthread_attr (%d)", errno);
        return NO;
    }
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    
    if(pthread_create(&thr, &attr, &exceptionServerThread, NULL) != 0)
    {
        URLog(@"Error: Failed to create exception server thread (%d)", errno);
        pthread_attr_destroy(&attr);
        return NO;
    }
    pthread_attr_destroy(&attr);
    
    _machServerThread = pthread_mach_thread_np(thr);
    
    // Register for the task
    mach_port_t result;
    pthread_mutex_lock(&_machServerLock);
    if((kr = mach_port_insert_right(mach_task_self(), _machServerPort, _machServerPort, MACH_MSG_TYPE_MAKE_SEND)) != KERN_SUCCESS)
    {
        URLog(@"Error: Failed to insert Mach send right (%d)", kr);
        return NO;
    }
    result = _machServerPort;
    pthread_mutex_unlock(&_machServerLock);
    
    if((kr = mach_port_mod_refs(mach_task_self(), result, MACH_PORT_RIGHT_SEND, 1)) != KERN_SUCCESS)
        URLog(@"Warning: Unexpected error incrementing mach port reference (%d)", kr);
    mach_port_deallocate(mach_task_self(), result);
    
    kr = task_swap_exception_ports(mach_task_self(), exc_mask, result, EXCEPTION_DEFAULT | MACH_EXCEPTION_CODES, MACHINE_THREAD_STATE,
                                   _prevMasks, &_prevCount, _prevPorts, _prevBehaviors, _prevFlavors);
    if(kr != KERN_SUCCESS)
    {
        URLog(@"Error: Failed to swap mach exception ports (%d)", kr);
        return NO;
    }
    
    return YES;
}

- (BOOL)start
{
    if(![super start])
        return NO;
    
    if(![self registerHandlerWithSIGABRT])
        return NO;
    
    if(![self registerHandlerInMachExceptionServer])
        return NO;
    
    return YES;
}

- (BOOL)stop
{
    if(![super stop])
        return NO;
    
    mach_msg_return_t mr;
    
    sigaction(SIGABRT, _oldSignalAction, NULL);
    
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&_machServerShouldStop);
    
    mach_msg_header_t msg;
    memset(&msg, 0, sizeof(msg));
    msg.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, MACH_MSG_TYPE_MAKE_SEND_ONCE);
    msg.msgh_local_port = MACH_PORT_NULL;
    msg.msgh_remote_port = _machNotifyPort;
    msg.msgh_size = sizeof(msg);
    msg.msgh_id = URQA_TERMINATE_MSGH_ID;
    
    if((mr = mach_msg(&msg, MACH_SEND_MSG, msg.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL)) != MACH_MSG_SUCCESS)
    {
        URLog(@"Error: Unexpected error sending termination message to background thread (%d)", mr);
        return NO;
    }
    
    pthread_mutex_lock(&_machServerLock);
    while(!_machServerStopDone)
        pthread_cond_wait(&_machServerCond, &_machServerLock);
    pthread_mutex_unlock(&_machServerLock);
    
    if(_machServerPort != MACH_PORT_NULL)
        mach_port_deallocate(mach_task_self(), _machServerPort);
    
    if (_machNotifyPort != MACH_PORT_NULL)
        mach_port_deallocate(mach_task_self(), _machNotifyPort);
    
    if (_machPortSet != MACH_PORT_NULL)
        mach_port_deallocate(mach_task_self(), _machPortSet);
    
    pthread_cond_destroy(&_machServerCond);
    pthread_mutex_destroy(&_machServerLock);
    
    return YES;
}

void sigabrtCallback(int signo, siginfo_t *info, ucontext_t *ucontext)
{
    // Logging
    
    void *array[5] = {info, ucontext, NULL, NULL, NULL};
    URQACrashCallback callback = [_signalHandler callback];
    callback(array, [_signalHandler tag]);
}

kern_return_t machExceptionCallback(task_t task, thread_t thread, exception_type_t exception_type, mach_exception_data_t code, mach_msg_type_number_t code_count)
{
    if(machExceptionForward(task, thread, exception_type, code, code_count) == KERN_SUCCESS)
        return KERN_SUCCESS;
    
    siginfo_t si;
    if(!machExceptionGetSiginfo(exception_type, code, code_count, CPU_TYPE_ANY, &si))
    {
        URLog("Debug: Unexpected error mapping Mach exception to a POSIX signal");
        return KERN_FAILURE;
    }
    
    // Logging
    
    void *array[5] = {&si, NULL, &exception_type, &code, &code_count};
    URQACrashCallback callback = [_signalHandler callback];
    callback(array, [_signalHandler tag]);
    
    return KERN_FAILURE;
}

kern_return_t machExceptionForward(task_t task, thread_t thread, exception_type_t exception_type, mach_exception_data_t code, mach_msg_type_number_t code_count)
{
    mach_port_t port;
    exception_behavior_t behavior;
    thread_state_flavor_t flavor;
    
    exception_mask_t fwd_mask = 0;
    switch(exception_type)
    {
        case EXC_BAD_ACCESS:
            fwd_mask = EXC_MASK_BAD_ACCESS;
            break;
            
        case EXC_BAD_INSTRUCTION:
            fwd_mask = EXC_MASK_BAD_INSTRUCTION;
            break;
            
        case EXC_ARITHMETIC:
            fwd_mask = EXC_MASK_ARITHMETIC;
            break;
            
        case EXC_EMULATION:
            fwd_mask = EXC_MASK_EMULATION;
            break;
            
        case EXC_BREAKPOINT:
            fwd_mask = EXC_MASK_BREAKPOINT;
            break;
            
        case EXC_SOFTWARE:
            fwd_mask = EXC_MASK_SOFTWARE;
            break;
            
        case EXC_SYSCALL:
            fwd_mask = EXC_MASK_SYSCALL;
            break;
            
        case EXC_MACH_SYSCALL:
            fwd_mask = EXC_MASK_MACH_SYSCALL;
            break;
            
        case EXC_RPC_ALERT:
            fwd_mask = EXC_MASK_RPC_ALERT;
            break;
            
        case EXC_CRASH:
            fwd_mask = EXC_MASK_CRASH;
            break;
            
#ifdef EXC_GUARD
        case EXC_GUARD:
            fwd_mask = EXC_MASK_GUARD;
            break;
#endif
            
        default:
            URLog("Debug: Unhandled exception type %d; exception_to_mask() should be updated", exception_type);
            fwd_mask = (1 << exception_type);
            break;
    }
    
    BOOL check = false;
    for(mach_msg_type_number_t i = 0; i < _prevCount; i++)
    {
        if(!MACH_PORT_VALID(_prevPorts[i]))
            continue;
        
        if(!(_prevMasks[i] & fwd_mask))
            continue;
        
        check = true;
        port = _prevPorts[i];
        behavior = _prevBehaviors[i];
        flavor = _prevFlavors[i];
        break;
    }
    if(!check)
        return KERN_FAILURE;
    
    thread_state_data_t thread_state;
    mach_msg_type_number_t thread_state_count;
    kern_return_t kr;
    
    exception_data_type_t code32[code_count];
    for(mach_msg_type_number_t i = 0; i < code_count; i++)
        code32[i] = (uint32_t)code[i];
    
    bool mach_exc_codes = false;
    if(behavior & MACH_EXCEPTION_CODES)
    {
        mach_exc_codes = true;
        behavior &= ~MACH_EXCEPTION_CODES;
    }
    
    if(behavior != EXCEPTION_DEFAULT)
    {
        thread_state_count = THREAD_STATE_MAX;
        if((kr = thread_get_state(thread, flavor, thread_state, &thread_state_count)) != KERN_SUCCESS)
        {
            URLog("Debug: Failed to fetch thread state for thread=0x%x, flavor=0x%x, kr=0x%x", thread, flavor, kr);
            return kr;
        }
    }
    
    switch (behavior)
    {
        case EXCEPTION_DEFAULT:
            if(!mach_exc_codes)
                return exception_raise(port, thread, task, exception_type, code32, code_count);
            break;
            
        case EXCEPTION_STATE:
            if(!mach_exc_codes)
                return exception_raise_state(port, exception_type, code32, code_count, &flavor,
                                             thread_state, thread_state_count, thread_state, &thread_state_count);
            break;
            
        case EXCEPTION_STATE_IDENTITY:
            if(!mach_exc_codes)
                return exception_raise_state_identity(port, thread, task, exception_type, code32,
                                                      code_count, &flavor, thread_state, thread_state_count, thread_state, &thread_state_count);
            break;
            
        default:
            break;
    }
    
    URLog("Debug: Unsupported exception behavior: 0x%x (MACH_EXCEPTION_CODES=%s)", behavior, mach_exc_codes ? "true" : "false");
    return KERN_FAILURE;
}

bool machExceptionGetSiginfo(exception_type_t exception_type, mach_exception_data_t codes, mach_msg_type_number_t code_count, cpu_type_t cpu_type, siginfo_t *siginfo)
{
    if(code_count < 2)
    {
        URLog("Debug: Unexpected Mach code count of %u; can't map to UNIX exception", code_count);
        return false;
    }
    
    mach_exception_code_t code = codes[0];
    mach_exception_subcode_t subcode = codes[1];
    switch(exception_type)
    {
        case EXC_BAD_ACCESS:
            if(code == KERN_INVALID_ADDRESS)
                siginfo->si_signo = SIGSEGV;
            else
                siginfo->si_signo = SIGBUS;
            siginfo->si_addr = (void*)subcode;
            break;
            
        case EXC_BAD_INSTRUCTION:
            siginfo->si_signo = SIGILL;
            siginfo->si_addr = (void*)subcode;
            break;
            
        case EXC_ARITHMETIC:
            siginfo->si_signo = SIGFPE;
            siginfo->si_addr = (void*)subcode;
            break;
            
        case EXC_EMULATION:
            siginfo->si_signo = SIGEMT;
            siginfo->si_addr = (void*)subcode;
            break;
            
        case EXC_SOFTWARE:
            switch (code)
        {
            case 0x10000:                           // EXC_UNIX_BAD_SYSCALL
                siginfo->si_signo = SIGSYS;
                break;
                
            case 0x10001:                           // EXC_UNIX_BAD_PIPE
                siginfo->si_signo = SIGPIPE;
                break;
                
            case 0x10002:                           // EXC_UNIX_ABORT
                siginfo->si_signo = SIGABRT;
                break;
                
            case EXC_SOFT_SIGNAL:
                siginfo->si_signo = SIGKILL;
                break;
                
            default:
                URLog("Debug: Unexpected EXC_SOFTWARE code of %lld", code);
                siginfo->si_signo = SIGABRT;
                break;
        }
            siginfo->si_addr = (void*)subcode;
            break;
            
        case EXC_BREAKPOINT:
            siginfo->si_signo = SIGTRAP;
            siginfo->si_addr = (void*)subcode;
            break;
            
        default:
            return false;
    }
    
    switch (siginfo->si_signo)
    {
        case SIGSEGV:
            switch (code)
        {
            case KERN_PROTECTION_FAILURE:
                siginfo->si_code = SEGV_ACCERR;
                break;
                
            case KERN_INVALID_ADDRESS:
                siginfo->si_code = SEGV_MAPERR;
                break;
                
            default:
                siginfo->si_code = SEGV_NOOP;
                break;
        }
            break;
            
        case SIGBUS:
            siginfo->si_code = BUS_ADRERR;
            break;
            
        case SIGILL:
            siginfo->si_code = ILL_NOOP;
            break;
            
        case SIGFPE:
            siginfo->si_code = FPE_NOOP;
            break;
            
        case SIGTRAP:
            siginfo->si_code = TRAP_BRKPT;
            break;
            
        case SIGEMT:
        case SIGSYS:
        case SIGPIPE:
        case SIGABRT:
        case SIGKILL:
            siginfo->si_code = 0x0;
            break;
            
        default:
            return false;
    }
    return true;
}

void *exceptionServerThread(void *arg)
{
    __Request__exception_raise_t *request = NULL;
    size_t request_size;
    kern_return_t kr;
    mach_msg_return_t mr;
    
    request_size = round_page(sizeof(*request));
    if((kr = vm_allocate(mach_task_self(), (vm_address_t *)&request, request_size, VM_FLAGS_ANYWHERE)) != KERN_SUCCESS)
    {
        fprintf(stderr, "Unexpected error in vm_allocate(): %x\n", kr);
        return NULL;
    }
    
    while(1)
    {
        request->Head.msgh_local_port = _machPortSet;
        request->Head.msgh_size = (mach_msg_size_t)request_size;
        
        mr = mach_msg(&request->Head, MACH_RCV_MSG | MACH_RCV_LARGE, 0, request->Head.msgh_size, _machPortSet, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
        if(mr == MACH_RCV_TOO_LARGE)
        {
            request_size = round_page(request->Head.msgh_size);
            vm_deallocate(mach_task_self(), (vm_address_t)request, request_size);
            
            if((kr = vm_allocate(mach_task_self(), (vm_address_t *)&request, request_size, VM_FLAGS_ANYWHERE)) != KERN_SUCCESS)
            {
                fprintf(stderr, "Unexpected error in vm_allocate(): 0x%x\n", kr);
                return NULL;
            }
            continue;
        }
        else if(mr != MACH_MSG_SUCCESS)
        {
            URLog(@"Debug: Unexpected error in mach_msg(): 0x%x", mr);
            continue;
        }
        else
        {
            if(request->Head.msgh_local_port == _machNotifyPort)
            {
                if(request->Head.msgh_id == MACH_NOTIFY_NO_SENDERS)
                    continue;
                
                if(request->Head.msgh_id == URQA_TERMINATE_MSGH_ID)
                {
                    if(_machServerShouldStop)
                    {
                        pthread_mutex_lock(&_machServerLock);
                        _machServerStopDone = true;
                        pthread_cond_signal(&_machServerCond);
                        pthread_mutex_unlock(&_machServerLock);
                        break;
                    }
                }
            }
            
            if(request->Head.msgh_size < sizeof(*request))
            {
                URLog(@"Debug: Unexpected message size of %" PRIu64, (uint64_t)request->Head.msgh_size);
                
                __Reply__exception_raise_t reply;
                memset(&reply, 0, sizeof(reply));
                reply.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(request->Head.msgh_bits), 0);
                reply.Head.msgh_local_port = MACH_PORT_NULL;
                reply.Head.msgh_remote_port = request->Head.msgh_remote_port;
                reply.Head.msgh_size = sizeof(reply);
                reply.NDR = NDR_record;
                reply.RetCode = KERN_FAILURE;
                reply.Head.msgh_id = request->Head.msgh_id + 100;
                
                mr = mach_msg(&reply.Head, MACH_SEND_MSG, reply.Head.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
                if(mr != MACH_MSG_SUCCESS)
                    URLog(@"Debug: Unexpected failure replying to Mach exception message: 0x%x", mr);
                
                continue;
            }
            
#if !defined(__LP64__)
            mach_exception_data_type_t code64[request->codeCnt];
            for(mach_msg_type_number_t i = 0; i < request->codeCnt; i++)
                code64[i] = (uint64_t)request->code[i];
#else
            if(request_size - sizeof(*request) < (sizeof(mach_exception_data_type_t) * request->codeCnt))
            {
                URLog(@"Debug: Request is too small to contain 64-bit mach exception codes (0x%zu)", request_size);
                continue;
            }
            mach_exception_data_type_t *code64 = (mach_exception_data_type_t *)request->code;
#endif
            
            kern_return_t exc_result;
            exc_result = machExceptionCallback(request->task.name, request->thread.name, request->exception, code64, request->codeCnt);
            
            __Reply__exception_raise_t reply;
            memset(&reply, 0, sizeof(reply));
            reply.Head.msgh_bits = MACH_MSGH_BITS(MACH_MSGH_BITS_REMOTE(request->Head.msgh_bits), 0);
            reply.Head.msgh_local_port = MACH_PORT_NULL;
            reply.Head.msgh_remote_port = request->Head.msgh_remote_port;
            reply.Head.msgh_size = sizeof(reply);
            reply.NDR = NDR_record;
            reply.RetCode = exc_result;
            reply.Head.msgh_id = request->Head.msgh_id + 100;
            
            mr = mach_msg(&reply.Head, MACH_SEND_MSG, reply.Head.msgh_size, 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL);
            if(mr != MACH_MSG_SUCCESS)
                URLog(@"Debug: Unexpected failure replying to Mach exception message: 0x%x", mr);
        }
    }
    
    if(request)
        vm_deallocate(mach_task_self(), (vm_address_t)request, request_size);
    
    return NULL;
}

@end
