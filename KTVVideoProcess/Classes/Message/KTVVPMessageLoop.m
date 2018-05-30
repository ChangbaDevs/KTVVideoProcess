//
//  KTVVPMessageLoop.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPMessageLoop.h"
#import "KTVVPObjectQueue.h"
#import "KTVVPLog.h"

@interface KTVVPMessageLoop ()

@property (nonatomic, strong) NSThread * thread;
@property (nonatomic, strong) NSCondition * finishedWaitingCondition;
@property (nonatomic, strong) NSCondition * stopedWaitingCondition;
@property (nonatomic, strong) KTVVPObjectQueue * messageQueue;
@property (nonatomic, assign) NSInteger numberOfMessages;
@property (nonatomic, assign) BOOL didClosed;
@property (nonatomic, assign) BOOL exited;

@end

@implementation KTVVPMessageLoop

- (instancetype)initWithIdentify:(NSString *)identify delegate:(id <KTVVPMessageLoopDelegate>)delegate
{
    if (self = [super init])
    {
        _identify = identify;
        _delegate = delegate;
        _finishedWaitingCondition = [[NSCondition alloc] init];
        _stopedWaitingCondition = [[NSCondition alloc] init];
        _messageQueue = [[KTVVPObjectQueue alloc] init];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(messageLoopThread) object:nil];
        _thread.qualityOfService = NSQualityOfServiceDefault;
        _thread.name = [NSString stringWithFormat:@"KTVVPMessageLoop-thread-%@", _identify];
    }
    return self;
}

- (void)dealloc
{
    KTVVPLog(@"%s", __func__);
}

- (void)start
{
    if (_didClosed || _running)
    {
        return;
    }
    _running = YES;
    [_thread start];
}

- (void)stop
{
    if (_didClosed)
    {
        return;
    }
    _didClosed = YES;
    [_messageQueue stop];
}

- (void)putMessage:(KTVVPMessage *)message
{
    [self putMessage:message delay:0];
}

- (void)putMessage:(KTVVPMessage *)message delay:(NSTimeInterval)delay
{
    if (_didClosed)
    {
        return;
    }
    [_finishedWaitingCondition lock];
    _numberOfMessages += 1;
    [_finishedWaitingCondition unlock];
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
                    [_finishedWaitingCondition lock];
                    _numberOfMessages -= 1;
                    [_finishedWaitingCondition broadcast];
                    [_finishedWaitingCondition unlock];
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
        if (message)
        {
            if ([self.delegate respondsToSelector:@selector(messageLoop:processingMessage:)])
            {
                [self.delegate messageLoop:self processingMessage:message];
            }
            else
            {
                [message drop];
            }
            [_finishedWaitingCondition lock];
            _numberOfMessages -= 1;
            [_finishedWaitingCondition broadcast];
            [_finishedWaitingCondition unlock];
        }
    }
    if (_stopCallback)
    {
        _stopCallback(self);
    }
    _exited = YES;
    [_stopedWaitingCondition lock];
    [_stopedWaitingCondition broadcast];
    [_stopedWaitingCondition unlock];
}

- (void)waitUntilFinished
{
    [_finishedWaitingCondition lock];
    while (_numberOfMessages > 0)
    {
        [_finishedWaitingCondition wait];
    }
    [_finishedWaitingCondition unlock];
}

- (void)waitUntilStoped
{
    [_stopedWaitingCondition lock];
    while (_running && !_exited)
    {
        [_stopedWaitingCondition wait];
    }
    [_stopedWaitingCondition unlock];
}

@end

