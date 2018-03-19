//
//  KTVVPProcessor.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPProcessor.h"
#import "KTVVPPipeline.h"

@interface KTVVPProcessor ()

@property (nonatomic, assign) BOOL didSetup;
@property (nonatomic, strong) NSArray <KTVVPPipeline *> * pipelines;
@property (nonatomic, strong) NSMutableArray <id <KTVVPInput>> * outputs;

@end

@implementation KTVVPProcessor

- (instancetype)initWithContext:(KTVVPContext *)context
                  filterClasses:(NSArray <Class> *)filterClasses
{
    if (self = [super init])
    {
        _context = context;
        _filterClasses = filterClasses;
        _maxConcurrentPipelineCount = 3;
    }
    return self;
}

- (void)setupIfNeed
{
    if (!_didSetup)
    {
        [self setup];
    }
}

- (void)setup
{
    _didSetup = YES;
    
    NSMutableArray * pipelines = [NSMutableArray arrayWithCapacity:_maxConcurrentPipelineCount];
    for (NSInteger i = 0; i < _maxConcurrentPipelineCount; i++)
    {
        KTVVPPipeline * obj = [[KTVVPPipeline alloc] initWithContext:_context
                                                       filterClasses:_filterClasses];
        [pipelines addObject:obj];
    }
    _pipelines = [pipelines copy];
    [_pipelines.firstObject setupIfNeed];
}


#pragma mark - KTVVPInput

- (void)putFrame:(KTVVPFrame *)frame
{
    [self setupIfNeed];
    
    for (KTVVPPipeline * pipeline in _pipelines)
    {
        if (!pipeline.processing)
        {
            [pipeline processFrame:frame completionHandler:^(KTVVPFrame * frame) {
                for (id <KTVVPInput> obj in _outputs)
                {
                    [obj putFrame:frame];
                }
            }];
        }
    }
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
