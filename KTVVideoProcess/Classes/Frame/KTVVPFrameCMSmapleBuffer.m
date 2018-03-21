//
//  KTVVPFrameCMSmapleBuffer.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameCMSmapleBuffer.h"

@interface KTVVPFrameCMSmapleBuffer ()

{
    CVOpenGLESTextureRef _cvOpenGLESTexture;
}

@property (nonatomic, assign) NSInteger readLockingCount;

@end

@implementation KTVVPFrameCMSmapleBuffer

- (KTVVPFrameType)type
{
    return KTVVPFrameTypeCMSampleBuffer;
}

- (void)uploadIfNeed:(KTVVPFrameUploader *)uploader
{
    if (self.didUpload)
    {
        return;
    }
    
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
                                                         &_cvOpenGLESTexture);
    if (error)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
    }
    
    self.texture = CVOpenGLESTextureGetName(_cvOpenGLESTexture);
    glBindTexture(GL_TEXTURE_2D, self.texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.textureOptions.magFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.textureOptions.wrapT);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    self.didUpload = YES;
}

- (void)setSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (sampleBuffer)
    {
        CFRetain(sampleBuffer);
    }
    [self clear];
    _sampleBuffer = sampleBuffer;
    if (_sampleBuffer)
    {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer);
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        KTVVPGLSize size = {width, height};
        self.size = size;
    }
}

- (void *)byteBuffer
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer);
    return CVPixelBufferGetBaseAddress(pixelBuffer);
}

- (NSUInteger)bytesPerRow
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer);
    return CVPixelBufferGetBytesPerRow(pixelBuffer);
}

- (void)lockForReading
{
    [super lockForReading];
    if (_readLockingCount == 0)
    {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    }
    _readLockingCount++;
}

- (void)unlockForReading
{
    [super unlockForReading];
    _readLockingCount--;
    if (_readLockingCount == 0)
    {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(_sampleBuffer);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
}

- (void)clear
{
    [super clear];
    if (_sampleBuffer)
    {
        CFRelease(_sampleBuffer);
        _sampleBuffer = NULL;
    }
    if (_cvOpenGLESTexture)
    {
        CFRelease(_cvOpenGLESTexture);
        _cvOpenGLESTexture = NULL;
    }
    KTVVPGLSize size = {0, 0};
    self.size = size;
    self.didUpload = NO;
}

@end
