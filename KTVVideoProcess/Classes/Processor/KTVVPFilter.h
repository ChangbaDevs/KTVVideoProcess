//
//  KTVVPFilter.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "KTVVPInput.h"
#import "KTVVPOutput.h"
#import "KTVVPContext.h"

@interface KTVVPFilter : NSObject <KTVVPInput, KTVVPOutput>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithContext:(KTVVPContext *)context
                      glContext:(EAGLContext *)glContext;

@property (nonatomic, strong, readonly) KTVVPContext * context;
@property (nonatomic, strong, readonly) EAGLContext * glContext;

- (void)setCurrentGLContextIfNeed;

@end
