//
//  KTVVPGLImageTexture.m
//  KTVVideoProcess
//
//  Created by Single on 2018/4/10.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLImageTexture.h"

@interface KTVVPGLImageTexture ()

@property (nonatomic, strong) UIImage *image;

@end

@implementation KTVVPGLImageTexture

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        _image = [UIImage imageWithContentsOfFile:path];
        _size = KTVVPSizeMake(_image.size.width, _image.size.height);
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    if (self = [super init]) {
        _image = image;
        _size = KTVVPSizeMake(_image.size.width, _image.size.height);
    }
    return self;
}

- (void)dealloc
{
    NSAssert(_texture == 0, @"must call destory befor dealloc.");
}

- (void)uploadIfNeeded
{
    if (_texture) {
        return;
    }
    CGImageRef cgImage = _image.CGImage;
    GLubyte *imageData = NULL;
    CFDataRef dataFromImageDataProvider = NULL;
    GLenum format = GL_BGRA;
    BOOL shouldRedrawUsingCoreGraphics = NO;
    if (CGImageGetBytesPerRow(cgImage) != _size.width * 4
        || CGImageGetBitsPerPixel(cgImage) != 32
        || CGImageGetBitsPerComponent(cgImage) != 8) {
        shouldRedrawUsingCoreGraphics = YES;
    } else {
        CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(cgImage);
        if ((bitmapInfo & kCGBitmapFloatComponents) != 0) {
            shouldRedrawUsingCoreGraphics = YES;
        } else {
            CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
            if (byteOrderInfo == kCGBitmapByteOrder32Little) {
                CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
                if (alphaInfo != kCGImageAlphaPremultipliedFirst
                    && alphaInfo != kCGImageAlphaFirst
                    && alphaInfo != kCGImageAlphaNoneSkipFirst) {
                    shouldRedrawUsingCoreGraphics = YES;
                }
            } else if (byteOrderInfo == kCGBitmapByteOrderDefault
                     || byteOrderInfo == kCGBitmapByteOrder32Big) {
                CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
                if (alphaInfo != kCGImageAlphaPremultipliedLast
                    && alphaInfo != kCGImageAlphaLast
                    && alphaInfo != kCGImageAlphaNoneSkipLast) {
                    shouldRedrawUsingCoreGraphics = YES;
                } else {
                    format = GL_RGBA;
                }
            }
        }
    }
    if (shouldRedrawUsingCoreGraphics) {
        imageData = (GLubyte *)calloc(1, _size.width * _size.height * 4);
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
        CGContextRef imageContext = CGBitmapContextCreate(imageData,
                                                          _size.width,
                                                          _size.height,
                                                          8,
                                                          _size.width * 4,
                                                          genericRGBColorspace,
                                                          kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGContextDrawImage(imageContext,
                           CGRectMake(0.0, 0.0, _size.width, _size.height),
                           cgImage);
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
    } else {
        dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
        imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    }
    glActiveTexture(GL_TEXTURE3);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _size.width, _size.height, 0, format, GL_UNSIGNED_BYTE, imageData);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    if (shouldRedrawUsingCoreGraphics) {
        free(imageData);
    } else {
        if (dataFromImageDataProvider) {
            CFRelease(dataFromImageDataProvider);
        }
    }
}

- (void)destory
{
    if (_texture) {
        glDeleteTextures(1, &_texture);
        _texture = 0;
    }
}

@end
