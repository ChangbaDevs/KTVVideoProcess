//
//  KTVVPGLProgram.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPGLDefines.h"

@interface KTVVPGLProgram : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *  Params can't be nil.
 */
- (instancetype)initWithGLContext:(EAGLContext *)glContext vertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

/**
 *  Get locations.
 */
- (GLuint)attributeLocation:(NSString *)attributeName;
- (GLuint)uniformLocation:(NSString *)uniformName;

- (BOOL)linked;
- (void)use;

@end
