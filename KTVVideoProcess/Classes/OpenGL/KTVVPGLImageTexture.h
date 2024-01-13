//
//  KTVVPGLImageTexture.h
//  KTVVideoProcess
//
//  Created by Single on 2018/4/10.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPGLDefines.h"
#import "KTVVPDefines.h"

@interface KTVVPGLImageTexture : NSObject

- (instancetype)initWithPath:(NSString *)path;
- (instancetype)initWithImage:(UIImage *)image;

@property (nonatomic, assign, readonly) GLuint texture;
@property (nonatomic, assign, readonly) KTVVPSize size;

/**
 *  Upload texture
 */
- (void)uploadIfNeeded;

- (void)destory;

@end
