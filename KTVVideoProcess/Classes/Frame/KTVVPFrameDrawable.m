//
//  KTVVPFrameDrawable.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameDrawable.h"
#import "EAGLContext+KTVVPExtension.h"

@interface KTVVPFrameDrawable ()

{
    GLuint _glFramebuffer;
    CVPixelBufferRef _cvPixelBuffer;
    CVOpenGLESTextureRef _cvOpenGLESTexture;
}

@end

@implementation KTVVPFrameDrawable

- (instancetype)initWithSize:(KTVVPGLSize)size
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
        
        self.size = size;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    [self.uploader.glContext setCurrentIfNeeded];
    if (_glFramebuffer)
    {
        glDeleteFramebuffers(1, &_glFramebuffer);
        _glFramebuffer = 0;
    }
    if (_cvPixelBuffer)
    {
        CFRelease(_cvPixelBuffer);
        _cvPixelBuffer = NULL;
    }
    
    if (_cvOpenGLESTexture)
    {
        CFRelease(_cvOpenGLESTexture);
        _cvOpenGLESTexture = NULL;
    }
    self.didUpload = NO;
}

- (KTVVPFrameType)type
{
    return KTVVPFrameTypeDrawable;
}

- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader
{
    if (self.didUpload)
    {
        return;
    }
    
    self.uploader = uploader;
    
    glGenFramebuffers(1, &_glFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _glFramebuffer);
    
    NSDictionary * attributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          self.size.width,
                                          self.size.height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef)attributes,
                                          &_cvPixelBuffer);
    if (result)
    {
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", result);
    }
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          uploader.glTextureCache,
                                                          _cvPixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          self.textureOptions.internalFormat,
                                                          self.size.width,
                                                          self.size.height,
                                                          self.textureOptions.format,
                                                          self.textureOptions.type,
                                                          0,
                                                          &_cvOpenGLESTexture);
    if (result)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", result);
    }
    self.texture = CVOpenGLESTextureGetName(_cvOpenGLESTexture);
    glBindTexture(CVOpenGLESTextureGetTarget(_cvOpenGLESTexture), self.texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.textureOptions.wrapT);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.texture, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    self.didUpload = YES;
}

- (void)bindFramebuffer
{
    glBindFramebuffer(GL_FRAMEBUFFER, _glFramebuffer);
    glViewport(0, 0, self.size.width, self.size.height);
}

- (CVPixelBufferRef)corePixelBuffer
{
    return _cvPixelBuffer;
}

@end
