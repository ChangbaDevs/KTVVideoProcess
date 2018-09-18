//
//  KTVVPGLTextureFrame.m
//  KTVShortVideoTest
//
//  Created by Single on 2018/4/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLTextureFrame.h"

@implementation KTVVPGLTextureFrame

- (KTVVPFrameType)type
{
    return KTVVPFrameTypeGLTexture;
}

- (void)dealloc
{
    if (self.texture)
    {
        KTVVPSetCurrentGLContextIfNeeded(self.uploader.glContext);
        GLuint texture = self.texture;
        glDeleteTextures(1, &texture);
        self.texture = 0;
    }
    [self clear];
}

- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader
{
    if (self.didUpload)
    {
        return;
    }
    NSAssert(_uploadTextureCallback && _releaseTextureCallback, @"Can't be nil.");
    if (!self.texture)
    {
        self.uploader = uploader;
        KTVVPSetCurrentGLContextIfNeeded(self.uploader.glContext);
        glActiveTexture(GL_TEXTURE1);
        GLuint texture;
        glGenTextures(1, &texture);
        self.texture = texture;
        glBindTexture(GL_TEXTURE_2D, self.texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.textureOptions.minFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.textureOptions.magFilter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.textureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.textureOptions.wrapT);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
    KTVVPSetCurrentGLContextIfNeeded(self.uploader.glContext);
    glBindTexture(GL_TEXTURE_2D, self.texture);
    _uploadTextureCallback(self);
    _releaseTextureCallback(self);
    _uploadTextureCallback = nil;
    _releaseTextureCallback = nil;
    glBindTexture(GL_TEXTURE_2D, 0);
    self.didUpload = YES;
}

- (void)setUploadTextureCallback:(void (^)(KTVVPGLTextureFrame *))uploadTextureCallback releaseTextureCallback:(void (^)(KTVVPGLTextureFrame *))releaseTextureCallback
{
    _uploadTextureCallback = uploadTextureCallback;
    _releaseTextureCallback = releaseTextureCallback;
}

- (void)clear
{
    [super clear];
    self.didUpload = NO;
    _uploadTextureCallback = nil;
    if (_releaseTextureCallback)
    {
        _releaseTextureCallback(self);
    }
    _releaseTextureCallback = nil;
}

@end
