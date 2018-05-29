//
//  KTVVPRGBFilter.m
//  KTVVideoProcess
//
//  Created by Single on 2018/5/29.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPRGBFilter.h"

static NSString * const kFragmentShaderString = KTV_GLES_STRINGIZE
(
 varying highp vec2 varying_textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 uniform highp float redAdjustment;
 uniform highp float greenAdjustment;
 uniform highp float blueAdjustment;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, varying_textureCoordinate);
     
     gl_FragColor = vec4(textureColor.r * redAdjustment, textureColor.g * greenAdjustment, textureColor.b * blueAdjustment, textureColor.a);
 }
 );

@interface KTVVPRGBFilter ()

@property (nonatomic, assign) GLint red_location;
@property (nonatomic, assign) GLint green_location;
@property (nonatomic, assign) GLint blue_location;

@end

@implementation KTVVPRGBFilter

- (instancetype)initWithGLContext:(EAGLContext *)glContext framePool:(KTVVPFramePool *)framePool frameUploader:(KTVVPFrameUploader *)frameUploader
{
    if (self = [super initWithGLContext:glContext framePool:framePool frameUploader:frameUploader])
    {
        _red = 1.0;
        _green = 1.0;
        _blue = 1.0;
    }
    return self;
}

- (NSString *)fragmentShaderString
{
    return kFragmentShaderString;
}

- (void)programCreated:(KTVVPGLProgram *)program
{
    _red_location = [program uniformLocation:@"redAdjustment"];
    _green_location = [program uniformLocation:@"greenAdjustment"];
    _blue_location = [program uniformLocation:@"blueAdjustment"];
}

- (void)programPrepare
{
    glUniform1f(_red_location, _red);
    glUniform1f(_green_location, _green);
    glUniform1f(_blue_location, _blue);
}

@end
