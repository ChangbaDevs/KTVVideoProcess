//
//  KTVVPBrightnessFilter.m
//  KTVVideoProcess
//
//  Created by Single on 2018/5/29.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPBrightnessFilter.h"

static NSString * const kFragmentShaderString = KTV_GLES_STRINGIZE
(
 varying highp vec2 varying_textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 uniform lowp float brightness;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, varying_textureCoordinate);
     
     gl_FragColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w);
 }
 );

@interface KTVVPBrightnessFilter ()

@property (nonatomic, assign) GLint brightness_location;

@end

@implementation KTVVPBrightnessFilter

- (instancetype)initWithGLContext:(EAGLContext *)glContext framePool:(KTVVPFramePool *)framePool frameUploader:(KTVVPFrameUploader *)frameUploader
{
    if (self = [super initWithGLContext:glContext framePool:framePool frameUploader:frameUploader]) {
        _brightness = 0.0;
    }
    return self;
}

- (NSString *)fragmentShaderString
{
    return kFragmentShaderString;
}

- (void)programCreated:(KTVVPGLProgram *)program
{
    _brightness_location = [program uniformLocation:@"brightness"];
}

- (void)programPrepare
{
    glUniform1f(_brightness_location, _brightness);
}

@end
