//
//  KTVVPGLUtils.m
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/29.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLUtils.h"

void KTVVPSetCurrentGLContextIfNeeded(EAGLContext * glContext)
{
    if ([EAGLContext currentContext] != glContext)
    {
        [EAGLContext setCurrentContext:glContext];
    }
}
