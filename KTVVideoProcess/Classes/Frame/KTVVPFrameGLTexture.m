//
//  KTVVPFrameGLTexture.m
//  KTVShortVideoTest
//
//  Created by Single on 2018/4/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameGLTexture.h"

@implementation KTVVPFrameGLTexture

- (void)dealloc
{
    if (self.texture)
    {
        [self.uploader.glContext setCurrentIfNeeded];
        GLuint texture = self.texture;
        glDeleteTextures(1, &texture);
        self.texture = 0;
    }
    self.didUpload = NO;
}

- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader
{
    if (self.didUpload)
    {
        return;
    }
    if (!self.uploadTextureCallback)
    {
        return;
    }
    if (!self.texture)
    {
        self.uploader = uploader;
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
    glBindTexture(GL_TEXTURE_2D, self.texture);
    self.uploadTextureCallback(self);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)clear
{
    [super clear];
    self.didUpload = NO;
    self.uploadTextureCallback = nil;
    
}

@end
