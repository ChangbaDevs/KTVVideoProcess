//
//  KTVVPBlackAndWhiteFilter.m
//  KTVVideoProcess
//
//  Created by Single on 2018/4/9.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPBlackAndWhiteFilter.h"

static NSString * const kFragmentShaderString = KTV_GLES_STRINGIZE
(
 varying highp vec2 varying_textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, varying_textureCoordinate);
     lowp float luminance = dot(textureColor.rgb, luminanceWeighting);
     
     gl_FragColor = vec4(vec3(luminance), textureColor.w);
 }
 );

@implementation KTVVPBlackAndWhiteFilter

- (NSString *)fragmentShaderString
{
    return kFragmentShaderString;
}

@end
