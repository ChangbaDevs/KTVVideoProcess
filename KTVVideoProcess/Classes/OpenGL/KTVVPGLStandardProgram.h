//
//  KTVVPGLStandardProgram.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/9.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPGLProgram.h"

@interface KTVVPGLStandardProgram : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithGLContext:(EAGLContext *)glContext;
- (instancetype)initWithGLContext:(EAGLContext *)glContext
               vertexShaderString:(NSString *)vertexShaderString
             fragmentShaderString:(NSString *)fragmentShaderString;

@property (nonatomic, strong, readonly) KTVVPGLProgram * program;

@property (nonatomic, assign, readonly) GLint position_location;
@property (nonatomic, assign, readonly) GLint textureCoordinate_location;
@property (nonatomic, assign, readonly) GLint inputImageTexture_location;

- (void)bindTexture:(GLuint)texture;
- (void)use;

@end
