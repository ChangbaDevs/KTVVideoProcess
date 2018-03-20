//
//  KTVVPGLToneCurveProgram.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface KTVVPGLToneCurveProgram : NSObject

@property (nonatomic, assign, readonly) GLint position_location;
@property (nonatomic, assign, readonly) GLint textureCoordinate_location;
@property (nonatomic, assign, readonly) GLint inputImageTexture_location;
@property (nonatomic, assign, readonly) GLint toneCurveTexture_location;

- (void)bindInputImageTexture:(GLuint)inputImageTexture
             toneCurveTexture:(GLuint)toneCurveTexture;
- (void)use;

@end
