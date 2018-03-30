//
//  KTVVPMessageLoop.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPMessageLoop.h"
#import "KTVVPObjectQueue.h"

@interface KTVVPMessageLoop ()

@property (nonatomic, strong) NSThread * thread;
@property (nonatomic, strong) NSCondition * waitingCondition;
@property (nonatomic, strong) KTVVPObjectQueue * messageQueue;
@property (nonatomic, assign) BOOL didClosed;

@end

@implementation KTVVPMessageLoop

- (instancetype)initWithIdentify:(NSString *)identify delegate:(id <KTVVPMessageLoopDelegate>)delegate
{
    if (self = [super init])
    {
        _identify = identify;
        _delegate = delegate;
        _waitingCondition = [[NSCondition alloc] init];
        _messageQueue = [[KTVVPObjectQueue alloc] init];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(messageLoopThread) object:nil];
        _thread.qualityOfService = NSQualityOfServiceDefault;
        _thread.name = [NSString stringWithFormat:@"KTVVPMessageLoop-thread-%@", _identify];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

- (void)run
{
    if (_didClosed)
    {
        return;
    }
    if (!_running)
    {
        _running = YES;
        [_thread start];
    }
}

- (void)stop
{
    if (_didClosed)
    {
        return;
    }
    _didClosed = YES;
    if (_running)
    {
        [_messageQueue broadcastAllSyncRequest];
    }
}

- (void)waitUntilFinished
{
    [_waitingCondition lock];
    while (_running)
    {
        [_waitingCondition wait];
    }
    [_waitingCondition unlock];
}

- (void)putMessage:(KTVVPMessage *)message
{
    if (!_running)
    {
        NSAssert(NO, @"Can't put message befor loop is running.");
        return;
    }
    [_messageQueue putObject:message];
}

- (void)putMessage:(KTVVPMessage *)message delay:(NSTimeInterval)delay
{
    if (delay > 0)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_messageQueue putObject:message];
        });
    }
    else
    {
         [_messageQueue putObject:message];
    }
}

- (void)messageLoopThread
{
    if (_startCallback)
    {
        _startCallback(self);
    }
    while (YES)
    {
        if (_didClosed)
        {
            while (YES)
            {
                KTVVPMessage * message = [_messageQueue getObjectAsync];
                if (message)
                {
                    [message drop];
                }
                else
                {
                    break;
                }
            }
            [_messageQueue destory];
            break;
        }
        KTVVPMessage * message = [_messageQueue getObjectSync];
        if (!message)
        {
            continue;
        }
        if ([self.delegate respondsToSelector:@selector(messageLoop:processingMessage:)])
        {
            [self.delegate messageLoop:self processingMessage:message];
        }
        else
        {
            [message drop];
        }
    }
    if (_finishCallback)
    {
        _finishCallback(self);
    }
    _running = NO;
    [_waitingCondition broadcast];
}

@end
