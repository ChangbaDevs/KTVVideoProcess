//
//  KTVVPGLStandardProgram.h
//  KTVVideoProcess
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
- (instancetype)initWithGLContext:(EAGLContext *)glContext vertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

/**
 *  Core program.
 */
@property (nonatomic, strong, readonly) KTVVPGLProgram * program;

/**
 *  Locations.
 */
@property (nonatomic, assign, readonly) GLint position_location;
@property (nonatomic, assign, readonly) GLint textureCoordinate_location;
@property (nonatomic, assign, readonly) GLint inputImageTexture_location;

/**
 *  Bind/Unbind texture.
 */
- (void)bindTexture:(GLuint)texture;
- (void)unbindTexture;

- (void)use;

@end
