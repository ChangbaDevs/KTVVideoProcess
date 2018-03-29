//
//  KTVVPGLRGBProgram.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface KTVVPGLRGBProgram : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithGLContext:(EAGLContext *)glContext;

@property (nonatomic, assign, readonly) GLint position_location;
@property (nonatomic, assign, readonly) GLint textureCoordinate_location;
@property (nonatomic, assign, readonly) GLint sampler_location;

- (void)bindTexture:(GLuint)texture;
- (void)use;

@end
