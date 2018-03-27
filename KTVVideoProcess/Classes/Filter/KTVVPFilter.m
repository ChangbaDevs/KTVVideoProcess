//
//  KTVVPFilter.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFilter.h"

@interface KTVVPFilter ()

@end

@implementation KTVVPFilter

- (instancetype)initWithContext:(KTVVPContext *)context;
{
    if (self = [super init])
    {
        _context = context;
        _enable = YES;
    }
    return self;
}

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    [self outputFrame:frame];
}

- (void)outputFrame:(KTVVPFrame *)frame
{
    [self.output inputFrame:frame fromSource:self];
}

@end
