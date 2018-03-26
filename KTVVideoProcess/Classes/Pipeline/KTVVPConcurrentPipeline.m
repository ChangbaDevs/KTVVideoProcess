//
//  KTVVPConcurrentPipeline.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/26.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPConcurrentPipeline.h"
#import "KTVVPSerialPipeline.h"
#import "KTVVPPipelinePrivate.h"

@interface KTVVPConcurrentPipeline () <KTVVPPipelinePrivate>

@property (nonatomic, strong) NSArray <KTVVPSerialPipeline *> * pipelines;

@end

@implementation KTVVPConcurrentPipeline

- (instancetype)initWithContext:(KTVVPContext *)context
                  filterClasses:(NSArray <Class> *)filterClasses
{
    if (self = [super initWithContext:context
                        filterClasses:filterClasses])
    {
        _maxConcurrentCount = 3;
    }
    return self;
}

- (void)setupInternal
{
    NSMutableArray * pipelines = [NSMutableArray arrayWithCapacity:_maxConcurrentCount];
    for (NSInteger i = 0; i < _maxConcurrentCount; i++)
    {
        KTVVPSerialPipeline * obj = [[KTVVPSerialPipeline alloc] initWithContext:self.context
                                                                   filterClasses:self.filterClasses];
        [pipelines addObject:obj];
    }
    _pipelines = [pipelines copy];
    [self resetPipelineOutputs];
    [_pipelines.firstObject setupIfNeeded];
}


#pragma mark - KTVVPFrameInput

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    [self setupIfNeeded];
    
    [frame lock];
    BOOL processing = NO;
    for (KTVVPSerialPipeline * pipeline in _pipelines)
    {
        if (!pipeline.processing)
        {
            [pipeline inputFrame:frame fromSource:source];
            processing = YES;
            break;
        }
    }
    if (!processing)
    {
        NSLog(@"KTVVPConcurrentPipeline: Frame did drop...");
    }
    [frame unlock];
}


#pragma mark - Output

- (void)addOutput:(id <KTVVPFrameInput>)output
{
    [super addOutput:output];
    [self resetPipelineOutputs];
}

- (void)addOutputs:(NSArray <id<KTVVPFrameInput>> *)outputs
{
    [super addOutputs:outputs];
    [self resetPipelineOutputs];
}

- (void)removeOutput:(id <KTVVPFrameInput>)output
{
    [super removeOutput:output];
    [self resetPipelineOutputs];
}

- (void)removeOutputs:(NSArray <id<KTVVPFrameInput>> *)outputs
{
    [super removeOutputs:outputs];
    [self resetPipelineOutputs];
}

- (void)removeAllOutputs
{
    [super removeAllOutputs];
    [self resetPipelineOutputs];
}

- (void)resetPipelineOutputs
{
    NSArray <id <KTVVPFrameInput>> * ouputs = self.outputs;
    for (KTVVPSerialPipeline * obj in _pipelines)
    {
        [obj removeAllOutputs];
        [obj addOutputs:ouputs];
    }
}

@end
