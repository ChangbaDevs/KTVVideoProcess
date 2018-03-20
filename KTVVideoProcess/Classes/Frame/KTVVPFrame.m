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
        _size = size;
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

- (void)uploadIfNeed:(KTVVPFrameUploader *)uploader {}
- (void)clear {}


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
