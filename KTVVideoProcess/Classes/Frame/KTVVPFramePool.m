//
//  KTVVPFramePool.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFramePool.h"

@interface KTVVPFramePool () <KTVVPFrameLockingDelegate>

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
    [frame lock];
    return frame;
}


#pragma mark - KTVVPFrameLockingDelegate

- (void)frameDidUnuse:(__kindof KTVVPFrame *)frame
{
    [frame clear];
    NSMutableSet <__kindof KTVVPFrame *> * frames = [_framesContainer objectForKey:frame.key];
    [frames addObject:frame];
}

@end
