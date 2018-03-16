//
//  KTVVPGLProgram.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface KTVVPGLProgram : NSObject

- (instancetype)initWithVertexShaderCString:(const char *)vertexShaderCString
                      fragmentShaderCString:(const char *)fragmentShaderCString;
- (instancetype)initWithVertexShaderString:(NSString *)vertexShaderString
                      fragmentShaderString:(NSString *)fragmentShaderString;

@property (nonatomic, copy, readonly) NSString * vertexShaderString;
@property (nonatomic, copy, readonly) NSString * fragmentShaderString;

@property (nonatomic, assign, readonly) BOOL linkSuccess;

- (GLuint)attributeLocation:(NSString *)attributeName;
- (GLuint)uniformLocation:(NSString *)uniformName;

- (void)use;

@end
