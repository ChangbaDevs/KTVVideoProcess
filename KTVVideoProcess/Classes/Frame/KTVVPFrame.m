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
        KTVVPGLSize size = {0, 0};
        _naturalSize = size;
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

- (KTVVPGLSize)transformSize
{
    BOOL exchangeXY = NO;
    if (_rotationMode == KTVVPRotationMode90
        || _rotationMode == KTVVPRotationMode270)
    {
        exchangeXY = YES;
    }
    if (exchangeXY)
    {
        KTVVPGLSize size = {_naturalSize.height, _naturalSize.width};
        return size;
    }
    return _naturalSize;
}

- (KTVVPFlipMode)textureFlipMode
{
    switch (_naturalFlipMode)
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
    _naturalSize = frame.naturalSize;
    _rotationMode = frame.rotationMode;
    _naturalFlipMode = frame.naturalFlipMode;
}

- (void)fillWithoutTransformWithFrame:(KTVVPFrame *)frame
{
    _time = frame.time;
    _naturalSize = frame.transformSize;
    _rotationMode = KTVVPRotationModeNone;
    _naturalFlipMode = KTVVPFlipModeNone;
}

- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader {}
- (void)clear {}


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
