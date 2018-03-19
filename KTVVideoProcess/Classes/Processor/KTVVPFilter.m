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

- (instancetype)initWithContext:(KTVVPContext *)context
                      glContext:(EAGLContext *)glContext;
{
    if (self = [super init])
    {
        _context = context;
        _glContext = glContext;
    }
    return self;
}


#pragma mark - KTVVPInput

- (void)putFrame:(KTVVPFrame *)frame
{
    
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

@end
