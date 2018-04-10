//
//  KTVVPGLImageTexture.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/10.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPDefines.h"
#import "KTVVPGLDefines.h"

@interface KTVVPGLImageTexture : NSObject

- (instancetype)initWithPath:(NSString *)path;
- (instancetype)initWithImage:(UIImage *)image;

@property (nonatomic, assign, readonly) GLuint texture;
@property (nonatomic, assign, readonly) KTVVPSize size;

- (void)uploadIfNeeded;
- (void)destory;

@end
