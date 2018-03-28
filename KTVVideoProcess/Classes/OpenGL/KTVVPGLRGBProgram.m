//
//  KTVVPGLRGBProgram.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLRGBProgram.h"
#import "KTVVPGLProgram.h"

#define KTV_GLES_STRINGIZE(x) #x

static const char vertex_shader_string[] = KTV_GLES_STRINGIZE
(
 attribute vec4 position;
 attribute vec2 textureCoordinate;
 varying vec2 varying_textureCoordinate;
 
 void main()
 {
     varying_textureCoordinate = textureCoordinate;
     gl_Position = position;
 }
 );

static const char fragment_shader_string[] = KTV_GLES_STRINGIZE
(
 uniform sampler2D samplerRGB;
 varying mediump vec2 varying_textureCoordinate;
 
 void main()
 {
     gl_FragColor = texture2D(samplerRGB, varying_textureCoordinate);
 }
 );

@interface KTVVPGLRGBProgram ()

@property (nonatomic, strong) KTVVPGLProgram * program;

@end

@implementation KTVVPGLRGBProgram

- (instancetype)init
{
    if (self = [super init])
    {
        _program = [[KTVVPGLProgram alloc] initWithVertexShaderCString:vertex_shader_string
                                                     fragmentShaderCString:fragment_shader_string];
        if (_program.linkSuccess)
        {
            _position_location = [_program attributeLocation:@"position"];
            _textureCoordinate_location = [_program attributeLocation:@"textureCoordinate"];
            _sampler_location = [_program uniformLocation:@"samplerRGB"];
        }
    }
    return self;
}

- (void)bindTexture:(GLuint)texture
{
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(_sampler_location, 4);
}

- (void)use
{
    [_program use];
}

@end
