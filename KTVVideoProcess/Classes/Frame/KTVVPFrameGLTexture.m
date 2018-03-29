//
//  KTVVPFrameGLTexture.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameGLTexture.h"
#import "EAGLContext+KTVVPExtension.h"

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
}

- (KTVVPFrameType)type
{
    return KTVVPFrameTypeTextureOnly;
}

- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader
{
    if (self.didUpload)
    {
        return;
    }
    
    self.uploader = uploader;
    
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, self.textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, self.textureOptions.magFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self.textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self.textureOptions.wrapT);
    glBindTexture(GL_TEXTURE_2D, 0);
    self.texture = texture;
    
    self.didUpload = YES;
}

@end
