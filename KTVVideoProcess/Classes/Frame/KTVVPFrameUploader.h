//
//  KTVVPFrameUploader.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/16.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface KTVVPFrameUploader : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithGLContext:(EAGLContext *)glContext;

@property (nonatomic, strong, readonly) EAGLContext * glContext;
@property (nonatomic, assign, readonly) CVOpenGLESTextureCacheRef glTextureCache;

@end
