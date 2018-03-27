//
//  KTVVPFrame.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrame.h"

@interface KTVVPFrame ()

@property (nonatomic, assign) NSInteger lockingCount;

@end

@implementation KTVVPFrame

+ (KTVVPGLTextureOptions)defaultTextureOptions
{
    KTVVPGLTextureOptions textureOptions;
    textureOptions.minFilter = GL_LINEAR;
    textureOptions.magFilter = GL_LINEAR;
    textureOptions.wrapS = GL_CLAMP_TO_EDGE;
    textureOptions.wrapT = GL_CLAMP_TO_EDGE;
    textureOptions.internalFormat = GL_RGBA;
    textureOptions.format = GL_BGRA;
    textureOptions.type = GL_UNSIGNED_BYTE;
    return textureOptions;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _textureOptions = [KTVVPFrame defaultTextureOptions];
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    [self clear];
}

- (KTVVPFrameType)type
{
    return KTVVPFrameTypeIdle;
}

- (KTVVPGLSize)finalSize
{
    BOOL exchangeXY = NO;
    if (_rotationMode == KTVVPRotationMode90
        || _rotationMode == KTVVPRotationMode270)
    {
        exchangeXY = YES;
    }
    if (exchangeXY)
    {
        KTVVPGLSize size = {_size.height, _size.width};
        return size;
    }
    return _size;
}

- (KTVVPRotationMode)completionRotationMode
{
    if (_rotationMode == KTVVPRotationMode90)
    {
        return KTVVPRotationMode270;
    }
    if (_rotationMode == KTVVPRotationMode270)
    {
        return KTVVPRotationMode90;
    }
    return _rotationMode;
}

- (KTVVPFlipMode)textureFlipMode
{
    switch (_flipMode)
    {
        case KTVVPFlipModeNone:
            return KTVVPFlipModeVertical;
        case KTVVPFlipModeHorizonal:
            return KTVVPFlipModeHorizonalAndVertical;
        case KTVVPFlipModeVertical:
            return KTVVPFlipModeNone;
        case KTVVPFlipModeHorizonalAndVertical:
            return KTVVPFlipModeHorizonal;
    }
    return KTVVPFlipModeNone;
}

- (void)fillWithFrame:(KTVVPFrame *)frame
{
    _time = frame.time;
    _size = frame.size;
    _rotationMode = frame.rotationMode;
    _flipMode = frame.flipMode;
}

- (void)fillWithoutTransformWithFrame:(KTVVPFrame *)frame
{
    _time = frame.time;
    _size = frame.finalSize;
    _rotationMode = KTVVPRotationModeNone;
    _flipMode = KTVVPFlipModeNone;
}

- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader {}

- (void)clear
{
    _time = kCMTimeInvalid;
    _rotationMode = KTVVPRotationModeNone;
    _flipMode = KTVVPFlipModeNone;
}


#pragma mark - Data

- (CVPixelBufferRef)corePixelBuffer {return nil;}
- (void *)byteBuffer {return nil;}
- (NSUInteger)bytesPerRow {return 0;}


#pragma mark - Reuse Key

+ (NSString *)key
{
    return NSStringFromClass([self class]);
}

+ (NSString *)keyWithAppendString:(NSString *)string
{
    return [[self key] stringByAppendingFormat:@"-%@", string];
}


#pragma mark - Locking

- (void)lock
{
    _lockingCount++;
}

- (void)unlock
{
    _lockingCount--;
    if (_lockingCount <= 0)
    {
        if ([_lockingDelegate respondsToSelector:@selector(frameDidUnuse:)])
        {
            [_lockingDelegate frameDidUnuse:self];
        }
    }
}

@end
