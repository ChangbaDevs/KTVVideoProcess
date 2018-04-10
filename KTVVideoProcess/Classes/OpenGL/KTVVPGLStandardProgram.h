//
//  KTVVPGLStandardProgram.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/9.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface KTVVPGLStandardProgram : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithGLContext:(EAGLContext *)glContext;
- (instancetype)initWithGLContext:(EAGLContext *)glContext
             fragmentShaderString:(NSString *)fragmentShaderString;

@property (nonatomic, assign, readonly) GLint position_location;
@property (nonatomic, assign, readonly) GLint textureCoordinate_location;
@property (nonatomic, assign, readonly) GLint inputImageTexture_location;

- (void)bindTexture:(GLuint)texture;
- (void)use;

@end
