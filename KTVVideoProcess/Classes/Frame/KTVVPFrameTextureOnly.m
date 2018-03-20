//
//  KTVVPFrameTextureOnly.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameTextureOnly.h"

@implementation KTVVPFrameTextureOnly

- (void)dealloc
{
    if (self.texture)
    {
        GLuint texture = self.texture;
        glDeleteTextures(1, &texture);
        self.texture = 0;
    }
}

- (KTVVPFrameType)type
{
    return KTVVPFrameTypeTextureOnly;
}

- (void)uploadIfNeed:(KTVVPFrameUploader *)uploader
{
    if (self.didUpload)
    {
        return;
    }
    
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
