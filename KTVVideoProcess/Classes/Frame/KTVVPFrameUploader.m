//
//  KTVVPFrameUploader.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/16.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameUploader.h"
#import "KTVVPLog.h"

@interface KTVVPFrameUploader ()

@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef glTextureCache;

@end

@implementation KTVVPFrameUploader

- (instancetype)initWithGLContext:(EAGLContext *)glContext
{
    if (self = [super init]) {
        _glContext = glContext;
    }
    return self;
}

- (void)dealloc
{
    KTVVPLog(@"%s", __func__);
    if (_glTextureCache) {
        KTVVPSetCurrentGLContextIfNeeded(_glContext);
        CVOpenGLESTextureCacheFlush(_glTextureCache, 0);
        CFRelease(_glTextureCache);
        _glTextureCache = NULL;
    }
}

- (CVOpenGLESTextureCacheRef)glTextureCache
{
    if (!_glTextureCache) {
        CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _glContext, NULL, &_glTextureCache);
        if (error) {
            KTVVPLog(@"KTVVPFrameUploader failed to create OpenGL texture cache.");
        }
    }
    return _glTextureCache;
}

@end
