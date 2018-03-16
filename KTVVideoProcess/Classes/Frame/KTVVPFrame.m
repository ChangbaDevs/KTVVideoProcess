//
//  KTVVPFrame.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrame.h"

@interface KTVVPFrame ()

@property (nonatomic, assign) BOOL didUpload;

@property (nonatomic, assign) CVOpenGLESTextureRef glRGBATexture;

@end

@implementation KTVVPFrame

+ (KTVVPGLTextureOptions)textureOptions
{
    static KTVVPGLTextureOptions textureOptions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        textureOptions.minFilter = GL_LINEAR;
        textureOptions.magFilter = GL_LINEAR;
        textureOptions.wrapS = GL_CLAMP_TO_EDGE;
        textureOptions.wrapT = GL_CLAMP_TO_EDGE;
        textureOptions.internalFormat = GL_RGBA;
        textureOptions.format = GL_BGRA;
        textureOptions.type = GL_UNSIGNED_BYTE;
    });
    return textureOptions;
}

- (instancetype)initWithTextureRef:(GLuint)texture
{
    if (self = [super init])
    {
        _type = KTVVPFrameTypeTextureRef;
        _texture = texture;
        _didUpload = YES;
    }
    return self;
}

- (instancetype)initWithTextureOptions:(KTVVPGLTextureOptions)textureOptions
{
    if (self = [super init])
    {
        _type = KTVVPFrameTypeTextureOnly;
        _textureOptions = textureOptions;
    }
    return self;
}

- (instancetype)initWithFramebufferSize:(KTVVPGLSize)framebufferSize
{
    return [self initWithFramebufferSize:framebufferSize
                          textureOptions:[KTVVPFrame textureOptions]];
}

- (instancetype)initWithFramebufferSize:(KTVVPGLSize)framebufferSize
                         textureOptions:(KTVVPGLTextureOptions)textureOptions
{
    if (self = [super init])
    {
        _type = KTVVPFrameTypeDrawable;
        _textureOptions = textureOptions;
        _framebufferSize = framebufferSize;
    }
    return self;
}

- (instancetype)initWithCMSmapleBuffer:(CMSampleBufferRef)sampleBuffer
{
    return [self initWithCMSmapleBuffer:sampleBuffer
                         textureOptions:[KTVVPFrame textureOptions]];
}

- (instancetype)initWithCMSmapleBuffer:(CMSampleBufferRef)sampleBuffer
                        textureOptions:(KTVVPGLTextureOptions)textureOptions
{
    if (self = [super init])
    {
        _type = KTVVPFrameTypeCMSampleBuffer;
        _textureOptions = textureOptions;
        _sampleBuffer = sampleBuffer;
        if (_sampleBuffer)
        {
            CFRetain(_sampleBuffer);
        }
    }
    return self;
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    return [self initWithCVPixelBuffer:pixelBuffer
                        textureOptions:[KTVVPFrame textureOptions]];
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
                       textureOptions:(KTVVPGLTextureOptions)textureOptions
{
    if (self = [super init])
    {
        _type = KTVVPFrameTypeCVPixelBuffer;
        _textureOptions = textureOptions;
        _pixelBuffer = pixelBuffer;
        if (_pixelBuffer)
        {
            CFRetain(_pixelBuffer);
        }
    }
    return self;
}

- (void)dealloc
{
    switch (_type)
    {
        case KTVVPFrameTypeTextureRef:
        {
            
        }
            break;
        case KTVVPFrameTypeTextureOnly:
        {
            
        }
            break;
        case KTVVPFrameTypeDrawable:
        {
            
        }
            break;
        case KTVVPFrameTypeCMSampleBuffer:
        {
            if (_sampleBuffer)
            {
                CFRelease(_sampleBuffer);
                _sampleBuffer = NULL;
            }
            if (_glRGBATexture)
            {
                CFRelease(_glRGBATexture);
                _glRGBATexture = NULL;
            }
        }
            break;
        case KTVVPFrameTypeCVPixelBuffer:
        {
            if (_pixelBuffer)
            {
                CFRelease(_pixelBuffer);
                _pixelBuffer = NULL;
            }
        }
            break;
    }
}

- (void)uploadIfNeed:(KTVVPFrameUploader *)uploader
{
    if (self.didUpload)
    {
        return;
    }
    switch (_type)
    {
        case KTVVPFrameTypeTextureRef:
            break;
        case KTVVPFrameTypeTextureOnly:
        {
            glGenTextures(1, &_texture);
            glBindTexture(GL_TEXTURE_2D, _texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
            
            self.didUpload = YES;
        }
            break;
        case KTVVPFrameTypeDrawable:
        {
            
        }
            break;
        case KTVVPFrameTypeCMSampleBuffer:
        {
            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer);
            
            int width = (int)CVPixelBufferGetWidth(pixelBuffer);
            int height = (int)CVPixelBufferGetHeight(pixelBuffer);
            
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            CVReturn error;
            error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                 uploader.glTextureCache,
                                                                 pixelBuffer,
                                                                 NULL,
                                                                 GL_TEXTURE_2D,
                                                                 GL_RGBA,
                                                                 width,
                                                                 height,
                                                                 GL_BGRA,
                                                                 GL_UNSIGNED_BYTE,
                                                                 0,
                                                                 &_glRGBATexture);
            if (error)
            {
                NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
            }
            
            _texture = CVOpenGLESTextureGetName(_glRGBATexture);
            glBindTexture(GL_TEXTURE_2D, _texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            
            self.didUpload = YES;
        }
            break;
        case KTVVPFrameTypeCVPixelBuffer:
        {
            
        }
            break;
    }
}

- (void)lock
{
    
}

- (void)unlock
{
    
}

@end
