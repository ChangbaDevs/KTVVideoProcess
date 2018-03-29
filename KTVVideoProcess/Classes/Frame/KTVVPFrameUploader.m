//
//  KTVVPFrameUploader.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/16.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameUploader.h"
#import "EAGLContext+KTVVPExtension.h"

@interface KTVVPFrameUploader ()

@property (nonatomic, strong) EAGLContext * glContext;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef glTextureCache;

@end

@implementation KTVVPFrameUploader

- (instancetype)initWithGLContext:(EAGLContext *)glContext
{
    if (self = [super init])
    {
        _glContext = glContext;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    if (_glTextureCache)
    {
        [_glContext setCurrentIfNeeded];
        CVOpenGLESTextureCacheFlush(_glTextureCache, 0);
        CFRelease(_glTextureCache);
        _glTextureCache = NULL;
    }
}

- (CVOpenGLESTextureCacheRef)glTextureCache
{
    if (!_glTextureCache)
    {
        CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _glContext, NULL, &_glTextureCache);
        if (error)
        {
            NSLog(@"KTVVPFrameUploader failed to create OpenGL texture cache.");
        }
    }
    return _glTextureCache;
}

@end
