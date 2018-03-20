//
//  KTVVPContext.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/16.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPContext.h"

@interface KTVVPContext ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, EAGLContext *> * glContexts;
@property (nonatomic, strong) NSMutableDictionary <NSString *, KTVVPFramePool *> * framePools;
@property (nonatomic, strong) NSMutableDictionary <NSString *, KTVVPFrameUploader *> * frameUploaders;

@end

@implementation KTVVPContext

- (instancetype)init
{
    if (self = [super init])
    {
        _mainGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _glContexts = [[NSMutableDictionary alloc] init];
        _framePools = [[NSMutableDictionary alloc] init];
        _frameUploaders = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    _mainGLContext = nil;
    [_glContexts removeAllObjects];
    [_frameUploaders removeAllObjects];
}

- (EAGLContext *)currentGLContext
{
    NSString * key = [self keyForCurrentThread];
    return [self glContextForKey:key];
}

- (KTVVPFramePool *)currentFramePool
{
    NSString * key = [self keyForCurrentThread];
    return [self framePoolForKey:key];
}

- (KTVVPFrameUploader *)currentFrameUploader
{
    NSString * key = [self keyForCurrentThread];
    return [self frameUploaderForKey:key];
}

- (EAGLContext *)glContextForKey:(NSString *)key
{
    EAGLContext * obj = [_glContexts objectForKey:key];
    if (!obj)
    {
        obj = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                    sharegroup:_mainGLContext.sharegroup];
        [_glContexts setObject:obj forKey:key];
    }
    return obj;
}

- (KTVVPFramePool *)framePoolForKey:(NSString *)key
{
    KTVVPFramePool * obj = [_framePools objectForKey:key];
    if (!obj)
    {
        obj = [[KTVVPFramePool alloc] init];
        [_framePools setObject:obj forKey:key];
    }
    return obj;
}

- (KTVVPFrameUploader *)frameUploaderForKey:(NSString *)key
{
    KTVVPFrameUploader * obj = [_frameUploaders objectForKey:key];
    if (!obj)
    {
        obj = [[KTVVPFrameUploader alloc] initWithGLContext:[self currentGLContext]];
        [_frameUploaders setObject:obj forKey:key];
    }
    return obj;
}

- (void)setCurrentGLContextIfNeed
{
    EAGLContext * obj = [self currentGLContext];
    if ([EAGLContext currentContext] != obj)
    {
        [EAGLContext setCurrentContext:obj];
    }
}

- (NSString *)keyForCurrentThread
{
    NSString * key = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
    return key;
}

@end
