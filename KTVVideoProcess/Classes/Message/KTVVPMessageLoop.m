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
        self.messageQueue = [[KTVVPObjectQueue alloc] init];
        self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(messageLoopThread) object:nil];
        self.thread.qualityOfService = NSQualityOfServiceDefault;
        self.thread.name = @"KTVVPMessageLoop-thread";
    }
    return self;
}

- (void)run
{
    [self.thread start];
}

- (void)stop
{
    self.didClosed = YES;
}

- (void)putMessage:(KTVVPMessage *)message
{
    [self.messageQueue putObject:message];
}

- (void)messageLoopThread
{
    while (YES)
    {
        if (self.didClosed)
        {
            break;
        }
        KTVVPMessage * message = [self.messageQueue getObjectSync];
        if (!message)
        {
            continue;
        }
        [self.delegate messageLoop:self processingMessage:message];
    }
}

@end
