//
//  EAGLContext+KTVVPExtension.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/29.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "EAGLContext+KTVVPExtension.h"

@implementation EAGLContext (KTVVPExtension)

- (void)setCurrentIfNeeded
{
    if ([EAGLContext currentContext] != self)
    {
        [EAGLContext setCurrentContext:self];
    }
}

@end
