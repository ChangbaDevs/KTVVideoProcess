//
//  KTVVPContext.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/16.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "KTVVPFramePool.h"
#import "KTVVPFrameUploader.h"

@interface KTVVPContext : NSObject

@property (nonatomic, strong, readonly) EAGLContext * mainGLContext;

- (EAGLContext *)currentGLContext;
- (KTVVPFramePool *)currentFramePool;
- (KTVVPFrameUploader *)currentFrameUploader;

- (EAGLContext *)glContextForKey:(NSString *)key;
- (KTVVPFramePool *)framePoolForKey:(NSString *)key;
- (KTVVPFrameUploader *)frameUploaderForKey:(NSString *)key;

- (void)setCurrentGLContextIfNeed;

@end
