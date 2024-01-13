//
//  KTVVPCVPixelBufferFrame.m
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/3.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPCVPixelBufferFrame.h"
#import "KTVVPLog.h"

@interface KTVVPCVPixelBufferFrame ()

@property (nonatomic, assign) CVOpenGLESTextureRef openGLESTexture;

@end

@implementation KTVVPCVPixelBufferFrame

- (KTVVPFrameType)type
{
    return KTVVPFrameTypeCVPixelBuffer;
}

- (instancetype)init
{
    if (self = [super init]) {
        KTVVPLog(@"%s", __func__);
    }
    return self;
}

- (void)dealloc
{
    KTVVPLog(@"%s", __func__);
}

- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader
{
    if (self.didUpload) {
        return;
    }
    self.uploader = uploader;
    KTVVPSetCurrentGLContextIfNeeded(self.uploader.glContext);
    CVPixelBufferRef pixelBuffer = _pixelBuffer;
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    GLenum format = GL_BGRA;
    GLenum type = GL_UNSIGNED_BYTE;
    GLint internalFormat = GL_RGBA;
    OSType formatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (formatType == kCVPixelFormatType_OneComponent8) {
        format = GL_LUMINANCE;
        type = GL_UNSIGNED_BYTE;
        internalFormat = GL_LUMINANCE;
    } else if (formatType == kCVPixelFormatType_DepthFloat16) {
        format = GL_LUMINANCE;
        type = GL_HALF_FLOAT_OES;
        internalFormat = GL_LUMINANCE;
    } else if (formatType == kCVPixelFormatType_DepthFloat32) {
        format = GL_LUMINANCE;
        type = GL_FLOAT;
        internalFormat = GL_LUMINANCE;
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CVReturn error;
    error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                         uploader.glTextureCache,
                                                         pixelBuffer,
                                                         NULL,
                                                         GL_TEXTURE_2D,
                                                         internalFormat,
                                                         width,
                                                         height,
                                                         format,
                                                         type,
                                                         0,
                                                         &_openGLESTexture);
    if (error) {
        KTVVPLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
    }
    self.texture = CVOpenGLESTextureGetName(_openGLESTexture);
    glBindTexture(GL_TEXTURE_2D, self.texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.textureOptions.magFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.textureOptions.wrapT);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    self.didUpload = YES;
}

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (pixelBuffer) {
        CFRetain(pixelBuffer);
    }
    [self clear];
    _pixelBuffer = pixelBuffer;
    if (_pixelBuffer) {
        int width = (int)CVPixelBufferGetWidth(_pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(_pixelBuffer);
        self.layout.size = KTVVPSizeMake(width, height);
    }
}

- (CVPixelBufferRef)corePixelBuffer
{
    return _pixelBuffer;
}

- (void)clear
{
    [super clear];
    KTVVPSetCurrentGLContextIfNeeded(self.uploader.glContext);
    if (_pixelBuffer) {
        CFRelease(_pixelBuffer);
        _pixelBuffer = NULL;
    }
    if (_openGLESTexture) {
        CFRelease(_openGLESTexture);
        _openGLESTexture = NULL;
    }
    self.layout.size = KTVVPSizeZero();
    self.uploader = nil;
    self.didUpload = NO;
}

@end
