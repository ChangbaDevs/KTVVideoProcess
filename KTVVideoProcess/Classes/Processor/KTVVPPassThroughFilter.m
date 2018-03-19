//
//  KTVVPPassThroughFilter.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPassThroughFilter.h"

@interface KTVVPPassThroughFilter ()

@end

@implementation KTVVPPassThroughFilter

- (instancetype)initWithContext:(KTVVPContext *)context
{
    if (self = [super initWithContext:context])
    {
        
    }
    return self;
}

- (void)putFrame:(KTVVPFrame *)frame
{
    [self.context setCurrentGLContextIfNeed];
    
    KTVVPGLSize size = {1280, 720};
    KTVVPFrame * result = [[KTVVPFrame alloc] initWithFramebufferSize:size];
    [result uploadIfNeed:[self.context currentFrameUploader]];
}

@end
