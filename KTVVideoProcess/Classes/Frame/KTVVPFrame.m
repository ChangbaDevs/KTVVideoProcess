//
//  KTVVPFrame.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrame.h"
#import "KTVVPFramePrivate.h"

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
        _layout = [[KTVVPFrameLayout alloc] init];
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
    return KTVVPFrameTypeUnknown;
}

- (void)fillWithFrame:(KTVVPFrame *)frame
{
    _timeStamp = frame.timeStamp;
    _hostTimeStamp = frame.hostTimeStamp;
    _layout.size = frame.layout.size;
    _layout.rotationMode = frame.layout.rotationMode;
    _layout.flipMode = frame.layout.flipMode;
    _extendedObject = frame.extendedObject;
    if (@available(iOS 11_1, *))
    {
        _depthData = frame.depthData;
    }
}

- (void)fillWithFrameWithoutTransform:(KTVVPFrame *)frame
{
    _timeStamp = frame.timeStamp;
    _hostTimeStamp = frame.hostTimeStamp;
    _layout.size = frame.layout.finalSize;
    _layout.rotationMode = KTVVPRotationMode0;
    _layout.flipMode = KTVVPFlipModeNone;
    _extendedObject = frame.extendedObject;
    if (@available(iOS 11.1, *))
    {
        _depthData = frame.depthData;
    }
}

- (void)clear
{
    _timeStamp = kCMTimeZero;
    _hostTimeStamp = kCMTimeZero;
    _layout.rotationMode = KTVVPRotationMode0;
    _layout.flipMode = KTVVPFlipModeNone;
    _extendedObject = nil;
    if (@available(iOS 11.1, *))
    {
        _depthData = nil;
    }
}

- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader
{
    
}

- (CVPixelBufferRef)corePixelBuffer
{
    return nil;
}

+ (NSString *)key
{
    return NSStringFromClass([self class]);
}

+ (NSString *)keyWithAppendString:(NSString *)string
{
    return [[self key] stringByAppendingFormat:@"-%@", string];
}

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
