//
//  KTVVPGLToneCurveProgram.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLToneCurveProgram.h"
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
 varying highp vec2 varying_textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D toneCurveTexture;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, varying_textureCoordinate);
     lowp float redCurveValue = texture2D(toneCurveTexture, vec2(textureColor.r, 0.0)).r;
     lowp float greenCurveValue = texture2D(toneCurveTexture, vec2(textureColor.g, 0.0)).g;
     lowp float blueCurveValue = texture2D(toneCurveTexture, vec2(textureColor.b, 0.0)).b;
     
     gl_FragColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
 }
 );

@interface KTVVPGLToneCurveProgram ()

@property (nonatomic, strong) KTVVPGLProgram * program;

@end

@implementation KTVVPGLToneCurveProgram

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
            _inputImageTexture_location = [_program uniformLocation:@"inputImageTexture"];
            _toneCurveTexture_location = [_program uniformLocation:@"toneCurveTexture"];
        }
    }
    return self;
}

- (void)bindInputImageTexture:(GLuint)inputImageTexture
             toneCurveTexture:(GLuint)toneCurveTexture
{
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, inputImageTexture);
    glUniform1i(_inputImageTexture_location, 2);
    
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, toneCurveTexture);
    glUniform1i(_toneCurveTexture_location, 3);
}

- (void)use
{
    [_program use];
}

@end
