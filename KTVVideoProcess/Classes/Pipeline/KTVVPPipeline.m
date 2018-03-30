//
//  KTVVPPipeline.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/26.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPipeline.h"
#import "KTVVPPipelinePrivate.h"

@interface KTVVPPipeline () <KTVVPPipelinePrivate>

@property (nonatomic, strong) NSLock * outputsLock;
@property (nonatomic, strong) NSMutableArray <id <KTVVPFrameInput>> * outputsInternal;

@end

@implementation KTVVPPipeline

- (instancetype)initWithContext:(KTVVPContext *)context
                  filterClasses:(NSArray <Class> *)filterClasses
{
    if (self = [super init])
    {
        NSAssert(filterClasses.count > 0, @"filterClasses can't be nil.");
        
        _context = context;
        _filterClasses = filterClasses;
        _needFlushBeforOutput = YES;
        _outputsLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)setupIfNeeded
{
    if (!_didSetup)
    {
        [self setupInternal];
        _didSetup = YES;
    }
}

- (void)setupInternal {}
- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source {}


#pragma mark - Output

- (NSArray <id <KTVVPFrameInput>> *)outputs
{
    [_outputsLock lock];
    NSArray * obj = [_outputsInternal copy];
    [_outputsLock unlock];
    return obj;
}

- (void)addOutput:(id <KTVVPFrameInput>)output
{
    [_outputsLock lock];
    if (!_outputsInternal)
    {
        _outputsInternal = [NSMutableArray array];
    }
    if (![_outputsInternal containsObject:output])
    {
        [_outputsInternal addObject:output];
    }
    [_outputsLock unlock];
}

- (void)addOutputs:(NSArray <id<KTVVPFrameInput>> *)outputs
{
    for (id<KTVVPFrameInput> obj in outputs)
    {
        [self addOutput:obj];
    }
}

- (void)removeOutput:(id <KTVVPFrameInput>)output
{
    [_outputsLock lock];
    [_outputsInternal removeObject:output];
    [_outputsLock unlock];
}

- (void)removeOutputs:(NSArray <id<KTVVPFrameInput>> *)outputs
{
    for (id<KTVVPFrameInput> obj in outputs)
    {
        [self removeOutput:obj];
    }
}

- (void)removeAllOutputs
{
    [_outputsLock lock];
    [_outputsInternal removeAllObjects];
    [_outputsLock unlock];
}

- (void)outputFrame:(KTVVPFrame *)frame
{
    if (_needFlushBeforOutput)
    {
        glFlush();
    }
    [frame lock];
    [_outputsLock lock];
    for (id <KTVVPFrameInput> obj in _outputsInternal)
    {
        [obj inputFrame:frame fromSource:self];
    }
    [_outputsLock unlock];
    [frame unlock];
}

@end
