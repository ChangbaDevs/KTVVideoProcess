//
//  KTVVPGLStandardProgram.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/9.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLStandardProgram.h"
#import "KTVVPGLProgram.h"

static NSString * const kVertexShaderString = KTV_GLES_STRINGIZE
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

static NSString * const kFragmentShaderString = KTV_GLES_STRINGIZE
(
 uniform sampler2D inputImageTexture;
 varying mediump vec2 varying_textureCoordinate;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, varying_textureCoordinate);
 }
 );

@interface KTVVPGLStandardProgram ()

@property (nonatomic, strong) KTVVPGLProgram * program;

@end

@implementation KTVVPGLStandardProgram

- (instancetype)initWithGLContext:(EAGLContext *)glContext
{
    return [self initWithGLContext:glContext
              fragmentShaderString:kFragmentShaderString];
}

- (instancetype)initWithGLContext:(EAGLContext *)glContext
             fragmentShaderString:(NSString *)fragmentShaderString
{
    if (self = [super init])
    {
        _program = [[KTVVPGLProgram alloc] initWithGLContext:glContext
                                          vertexShaderString:kVertexShaderString
                                        fragmentShaderString:fragmentShaderString];
        if (_program.linkSuccess)
        {
            _position_location = [_program attributeLocation:@"position"];
            _textureCoordinate_location = [_program attributeLocation:@"textureCoordinate"];
            _inputImageTexture_location = [_program uniformLocation:@"inputImageTexture"];
        }
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

- (void)bindTexture:(GLuint)texture
{
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, texture);
    glUniform1i(_inputImageTexture_location, 4);
}

- (void)use
{
    [_program use];
}


@end
