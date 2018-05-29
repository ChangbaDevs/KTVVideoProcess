//
//  KTVVPGLDrawableFrame.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLDrawableFrame.h"

@interface KTVVPGLDrawableFrame ()

@property (nonatomic, assign) GLuint glFramebuffer;
@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;
@property (nonatomic, assign) CVOpenGLESTextureRef openGLESTexture;

@end

@implementation KTVVPGLDrawableFrame

- (KTVVPFrameType)type
{
    return KTVVPFrameTypeGLDrawable;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    KTVVPSetCurrentGLContextIfNeeded(self.uploader.glContext);
    if (_glFramebuffer)
    {
        glDeleteFramebuffers(1, &_glFramebuffer);
        _glFramebuffer = 0;
    }
    if (_pixelBuffer)
    {
        CFRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
    
    if (_openGLESTexture)
    {
        CFRelease(_openGLESTexture);
        _openGLESTexture = NULL;
    }
    self.didUpload = NO;
}

- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader
{
    if (self.didUpload)
    {
        return;
    }
    if (self.layout.size.width <= 0 || self.layout.size.height <= 0)
    {
        NSAssert(NO, @"KTVVPGLDrawableFrame: size can't be zero.");
        return;
    }
    self.uploader = uploader;
    KTVVPSetCurrentGLContextIfNeeded(self.uploader.glContext);
    glGenFramebuffers(1, &_glFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _glFramebuffer);
    NSDictionary * attributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          self.layout.size.width,
                                          self.layout.size.height,
                                          kCVPixelFormatType_32BGRA,
                                          (__bridge CFDictionaryRef)attributes,
                                          &_pixelBuffer);
    if (result)
    {
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", result);
    }
    result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          uploader.glTextureCache,
                                                          self.pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          self.textureOptions.internalFormat,
                                                          self.layout.size.width,
                                                          self.layout.size.height,
                                                          self.textureOptions.format,
                                                          self.textureOptions.type,
                                                          0,
                                                          &_openGLESTexture);
    if (result)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", result);
    }
    self.texture = CVOpenGLESTextureGetName(_openGLESTexture);
    glBindTexture(CVOpenGLESTextureGetTarget(_openGLESTexture), self.texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.textureOptions.wrapT);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    self.didUpload = YES;
}

- (void)bindDrawable
{
    glBindFramebuffer(GL_FRAMEBUFFER, self.glFramebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.texture, 0);
    glViewport(0, 0, self.layout.size.width, self.layout.size.height);
}

- (void)unbindDrawable
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void)fillColorBlack
{
    [self fillColorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
}

- (void)fillColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha
{
    glClearColor(red, green, blue, alpha);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (CVPixelBufferRef)corePixelBuffer
{
    return _pixelBuffer;
}

@end
