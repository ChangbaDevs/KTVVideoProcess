//
//  KTVVPConcurrentPipeline.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/26.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPConcurrentPipeline.h"
#import "KTVVPSerialPipeline.h"
#import "KTVVPLog.h"

@interface KTVVPConcurrentPipeline ()

@property (nonatomic, strong) NSArray <KTVVPSerialPipeline *> *pipelines;

@end

@implementation KTVVPConcurrentPipeline

- (instancetype)initWithContext:(KTVVPContext *)context filterClasses:(NSArray <Class> *)filterClasses
{
    if (self = [super initWithContext:context filterClasses:filterClasses]) {
        KTVVPLog(@"%s", __func__);
        _maxConcurrentCount = 3;
    }
    return self;
}

- (void)dealloc
{
    KTVVPLog(@"%s", __func__);
}

- (void)setupInternal
{
    __weak typeof(self) weakSelf = self;
    NSMutableArray *pipelines = [NSMutableArray arrayWithCapacity:_maxConcurrentCount];
    for (NSInteger i = 0; i < _maxConcurrentCount; i++) {
        KTVVPSerialPipeline *obj = [[KTVVPSerialPipeline alloc] initWithContext:self.context
                                                                   filterClasses:self.filterClasses];
        [obj setFilterConfigurationCallback:^(__kindof KTVVPFilter *filter, NSInteger index) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSInteger serialPipelineIndex = i;
            if (strongSelf.filterConfigurationCallback) {
                strongSelf.filterConfigurationCallback(filter, index, serialPipelineIndex);
            }
        }];
        obj.needFlushBeforOutput = self.needFlushBeforOutput;
        [pipelines addObject:obj];
    }
    _pipelines = [pipelines copy];
    [self resetPipelineOutputs];
    [_pipelines.firstObject setupIfNeeded];
}

- (NSArray <KTVVPFilter *> *)filtersOfClass:(Class)queryClass
{
    NSMutableArray <KTVVPFilter *> *ret = nil;
    for (KTVVPSerialPipeline *pipeline in [_pipelines copy]) {
        NSArray *filters = [pipeline filtersOfClass:queryClass];
        if (filters.count > 0) {
            if (!ret) {
                ret = [NSMutableArray array];
            }
            [ret addObjectsFromArray:filters];
        }
    }
    return ret;
}

#pragma mark - KTVVPFrameInput

- (BOOL)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    [self setupIfNeeded];
    [frame lock];
    BOOL ret = NO;
    for (KTVVPSerialPipeline *pipeline in _pipelines) {
        if (!pipeline.processing) {
            [pipeline inputFrame:frame fromSource:source];
            ret = YES;
            break;
        }
    }
    if (!ret) {
        KTVVPLog(@"KTVVPConcurrentPipeline: Frame did drop...");
    }
    [frame unlock];
    return ret;
}

#pragma mark - OpenGL

- (void)setNeedFlushBeforOutput:(BOOL)needFlushBeforOutput
{
    [super setNeedFlushBeforOutput:needFlushBeforOutput];
    for (KTVVPSerialPipeline *pipeline in _pipelines) {
        pipeline.needFlushBeforOutput = needFlushBeforOutput;
    }
}

- (void)glFinish
{
    for (KTVVPSerialPipeline *pipeline in _pipelines) {
        [pipeline glFinish];
    }
}

#pragma mark - Control

- (void)waitUntilFinished
{
    for (KTVVPSerialPipeline *pipeline in _pipelines) {
        [pipeline waitUntilFinished];
    }
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
    NSArray <id <KTVVPFrameInput>> *ouputs = self.outputs;
    for (KTVVPSerialPipeline *obj in _pipelines) {
        [obj removeAllOutputs];
        [obj addOutputs:ouputs];
    }
}

@end
