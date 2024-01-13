//
//  KTVVPFilter.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPFrameInput.h"
#import "KTVVPFramePool.h"

@interface KTVVPFilter : NSObject <KTVVPFrameInput>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *  @param glContext     The OpenGL context for current enviroment.
 *  @param framePool     The frame pool for current enviroment.
 *  @param frameUploader The frame uploader for current enviroment.
 */
- (instancetype)initWithGLContext:(EAGLContext *)glContext framePool:(KTVVPFramePool *)framePool frameUploader:(KTVVPFrameUploader *)frameUploader;

/**
 *  Environment
 */
@property (nonatomic, strong, readonly) EAGLContext *glContext;
@property (nonatomic, strong, readonly) KTVVPFramePool *framePool;
@property (nonatomic, strong, readonly) KTVVPFrameUploader *frameUploader;

/**
 *  Default value is YES.
 */
@property (nonatomic, assign) BOOL enable;

/**
 *  Filter relationship
 */
@property (nonatomic, weak) __kindof KTVVPFilter *parentFilter;

/**
 *  Output
 */
@property (atomic, weak) id <KTVVPFrameInput> output;

@end
