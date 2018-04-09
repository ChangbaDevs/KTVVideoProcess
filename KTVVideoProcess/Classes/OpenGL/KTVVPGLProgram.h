//
//  KTVVPGLProgram.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPGLDefines.h"

@interface KTVVPGLProgram : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithGLContext:(EAGLContext *)glContext
               vertexShaderString:(NSString *)vertexShaderString
             fragmentShaderString:(NSString *)fragmentShaderString;

@property (nonatomic, copy, readonly) NSString * vertexShaderString;
@property (nonatomic, copy, readonly) NSString * fragmentShaderString;

@property (nonatomic, assign, readonly) BOOL linkSuccess;

- (GLuint)attributeLocation:(NSString *)attributeName;
- (GLuint)uniformLocation:(NSString *)uniformName;

- (void)use;

@end
