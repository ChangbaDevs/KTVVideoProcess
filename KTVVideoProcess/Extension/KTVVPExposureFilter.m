//
//  KTVVPExposureFilter.m
//  KTVVideoProcess
//
//  Created by Single on 2018/5/29.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPExposureFilter.h"

#undef pow

static NSString * const kFragmentShaderString = KTV_GLES_STRINGIZE
(
 varying highp vec2 varying_textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 uniform lowp float exposure;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, varying_textureCoordinate);
     
     gl_FragColor = vec4(textureColor.rgb * pow(2.0, exposure), textureColor.w);
 }
 );

@interface KTVVPExposureFilter ()

@property (nonatomic, assign) GLint exposure_location;

@end

@implementation KTVVPExposureFilter

- (instancetype)initWithGLContext:(EAGLContext *)glContext framePool:(KTVVPFramePool *)framePool frameUploader:(KTVVPFrameUploader *)frameUploader
{
    if (self = [super initWithGLContext:glContext framePool:framePool frameUploader:frameUploader]) {
        _exposure = 0.0;
    }
    return self;
}

- (NSString *)fragmentShaderString
{
    return kFragmentShaderString;
}

- (void)programCreated:(KTVVPGLProgram *)program
{
    _exposure_location = [program uniformLocation:@"exposure"];
}

- (void)programPrepare
{
    glUniform1f(_exposure_location, _exposure);
}

@end
