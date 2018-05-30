//
//  KTVVPContext.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/16.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPContext.h"
#import "KTVVPLog.h"

@implementation KTVVPContext

+ (instancetype)sharedContext
{
    static KTVVPContext * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[KTVVPContext alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _mainGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    return self;
}

- (void)dealloc
{
    KTVVPLog(@"%s", __func__);
}

@end
