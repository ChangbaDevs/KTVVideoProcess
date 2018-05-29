//
//  KTVVPFilter.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFilter.h"

@implementation KTVVPFilter

- (instancetype)initWithGLContext:(EAGLContext *)glContext
                        framePool:(KTVVPFramePool *)framePool
                    frameUploader:(KTVVPFrameUploader *)frameUploader
{
    if (self = [super init])
    {
        _glContext = glContext;
        _framePool = framePool;
        _frameUploader = frameUploader;
        _enable = YES;
    }
    return self;
}

- (BOOL)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    source = _parentFilter ? _parentFilter : self;
    return [self.output inputFrame:frame fromSource:source];
}

@end
