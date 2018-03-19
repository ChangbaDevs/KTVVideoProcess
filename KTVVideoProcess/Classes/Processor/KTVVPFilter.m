//
//  KTVVPFilter.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFilter.h"

@interface KTVVPFilter ()

@property (nonatomic, strong) NSMutableArray <id <KTVVPInput>> * outputs;

@end

@implementation KTVVPFilter

- (instancetype)initWithContext:(KTVVPContext *)context;
{
    if (self = [super init])
    {
        _context = context;
    }
    return self;
}


#pragma mark - KTVVPInput

- (void)putFrame:(KTVVPFrame *)frame
{
    [self outputFrame:frame];
}


#pragma mark - KTVVPOutput

- (void)addInput:(id <KTVVPInput>)input
{
    if (!_outputs)
    {
        _outputs = [NSMutableArray array];
    }
    [_outputs addObject:input];
}

- (void)removeInput:(id <KTVVPInput>)input
{
    [_outputs removeObject:input];
}

- (void)outputFrame:(KTVVPFrame *)frame
{
    [frame lock];
    for (id <KTVVPInput> obj in _outputs)
    {
        [obj putFrame:frame];
    }
    [frame unlock];
}

@end
