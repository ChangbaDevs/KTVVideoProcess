//
//  KTVVPSource.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/26.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPSource.h"

@implementation KTVVPSource

- (instancetype)initWithContext:(KTVVPContext *)context
{
    if (self = [super init])
    {
        _context = context;
    }
    return self;
}

- (void)start {}
- (void)stop {}

@end
