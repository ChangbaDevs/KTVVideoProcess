//
//  KTVVPFilter.h
//  KTVVideoProcessDemo
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

- (instancetype)initWithGLContext:(EAGLContext *)glContext
                        framePool:(KTVVPFramePool *)framePool
                    frameUploader:(KTVVPFrameUploader *)frameUploader;

@property (nonatomic, strong, readonly) EAGLContext * glContext;
@property (nonatomic, strong, readonly) KTVVPFramePool * framePool;
@property (nonatomic, strong, readonly) KTVVPFrameUploader * frameUploader;

@property (nonatomic, assign) BOOL enable;      // default is YES.


#pragma mark - Output

@property (atomic, weak) id <KTVVPFrameInput> output;

- (void)outputFrame:(KTVVPFrame *)frame;

@end
