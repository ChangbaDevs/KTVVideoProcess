//
//  KTVVPGLImageTexture.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/10.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLImageTexture.h"

@interface KTVVPGLImageTexture ()

@property (nonatomic, copy) NSString * path;
@property (nonatomic, strong) UIImage * image;
@property (nonatomic, strong) GLKTextureInfo * textureInfo;

@end

@implementation KTVVPGLImageTexture

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init])
    {
        _path = path;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    if (self = [super init])
    {
        _image = image;
    }
    return self;
}

- (void)dealloc
{
    NSAssert(_texture == 0 && _textureInfo == nil, @"must call destory befor dealloc.");
}

- (void)uploadIfNeeded
{
    if (_texture && _textureInfo)
    {
        return;
    }
    if (_image)
    {
        _textureInfo = [GLKTextureLoader textureWithCGImage:_image.CGImage options:nil error:nil];
    }
    else if (_path)
    {
        _textureInfo = [GLKTextureLoader textureWithContentsOfFile:_path options:nil error:nil];
    }
    _texture = _textureInfo.name;
    _size = KTVVPSizeMake(_textureInfo.width, _textureInfo.height);
}

- (void)destory
{
    if (_textureInfo)
    {
        _textureInfo = nil;
    }
    if (_texture)
    {
        glDeleteTextures(1, &_texture);
        _texture = 0;
    }
}

@end
