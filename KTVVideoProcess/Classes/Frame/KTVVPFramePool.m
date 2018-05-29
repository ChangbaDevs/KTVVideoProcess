//
//  KTVVPFramePool.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFramePool.h"
#import "KTVVPFramePrivate.h"

@interface KTVVPFramePool () <NSLocking, KTVVPFrameLockingDelegate>

@property (nonatomic, strong) NSLock * coreLock;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableSet <__kindof KTVVPFrame *> *> * framesContainer;

@end

@implementation KTVVPFramePool

- (instancetype)init
{
    if (self = [super init])
    {
        _framesContainer = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

- (__kindof KTVVPFrame *)frameWithKey:(NSString *)key factory:(__kindof KTVVPFrame *(^)(void))factory
{
    [self lock];
    NSMutableSet <__kindof KTVVPFrame *> * frames = [_framesContainer objectForKey:key];
    if (!frames)
    {
        frames = [NSMutableSet set];
        [_framesContainer setObject:frames forKey:key];
    }
    __kindof KTVVPFrame * frame = frames.anyObject;
    if (frame)
    {
        [frames removeObject:frame];
    }
    else if (factory)
    {
        frame = factory();
    }
    frame.lockingDelegate = self;
    frame.key = key;
    [frame clear];
    [frame lock];
    [self unlock];
    return frame;
}

#pragma mark - KTVVPFrameLockingDelegate

- (void)frameDidUnuse:(__kindof KTVVPFrame *)frame
{
    [self lock];
    NSMutableSet <__kindof KTVVPFrame *> * frames = [_framesContainer objectForKey:frame.key];
    [frames addObject:frame];
    [self unlock];
}

- (void)lock
{
    if (!self.coreLock)
    {
        self.coreLock = [[NSLock alloc] init];
    }
    [self.coreLock lock];
}

- (void)unlock
{
    [self.coreLock unlock];
}

@end
