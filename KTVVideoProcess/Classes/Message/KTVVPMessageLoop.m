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
@property (nonatomic, strong) KTVVPObjectQueue * messageQueue;
@property (nonatomic, assign) BOOL didClosed;

@end

@implementation KTVVPMessageLoop

- (instancetype)init
{
    if (self = [super init])
    {
        _messageQueue = [[KTVVPObjectQueue alloc] init];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(messageLoopThread) object:nil];
        _thread.qualityOfService = NSQualityOfServiceDefault;
        _thread.name = @"KTVVPMessageLoop-thread";
    }
    return self;
}

- (void)run
{
    [_thread start];
}

- (void)stop
{
    _didClosed = YES;
}

- (void)putMessage:(KTVVPMessage *)message
{
    [_messageQueue putObject:message];
}

- (void)messageLoopThread
{
    while (YES)
    {
        if (_didClosed)
        {
            break;
        }
        KTVVPMessage * message = [_messageQueue getObjectSync];
        if (!message)
        {
            continue;
        }
        [self.delegate messageLoop:self processingMessage:message];
    }
}

@end
