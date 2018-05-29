//
//  KTVVPSerialPipeline.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/23.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPSerialPipeline.h"
#import "KTVVPMessageLoop.h"

@interface KTVVPSerialPipeline () <KTVVPMessageLoopDelegate>

@property (nonatomic, assign) BOOL processing;

@property (nonatomic, strong) EAGLContext * glContext;
@property (nonatomic, strong) KTVVPFramePool * framePool;
@property (nonatomic, strong) KTVVPFrameUploader * frameUploader;

@property (nonatomic, strong) NSArray <KTVVPFilter *> * filters;
@property (nonatomic, strong) KTVVPMessageLoop * messageLoop;

@end

@implementation KTVVPSerialPipeline

- (instancetype)initWithContext:(KTVVPContext *)context filterClasses:(NSArray <Class> *)filterClasses
{
    if (self = [super initWithContext:context filterClasses:filterClasses])
    {
        NSLog(@"%s", __func__);
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    [_messageLoop stop];
    _messageLoop = nil;
}

- (void)setupInternal
{
    _messageLoop = [[KTVVPMessageLoop alloc] initWithIdentify:@"Pipeline" delegate:self];
    [_messageLoop start];
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLSetupContext object:nil]];
}

- (NSArray <KTVVPFilter *> *)filtersOfClass:(Class)queryClass
{
    NSMutableArray <KTVVPFilter *> * ret = nil;
    for (KTVVPFilter * obj in [_filters copy])
    {
        if ([obj isKindOfClass:queryClass])
        {
            if (!ret)
            {
                ret = [NSMutableArray array];
            }
            [ret addObject:obj];
        }
    }
    return ret;
}

#pragma mark - OpenGL

- (void)glFinish
{
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLFinish object:nil]];
}

#pragma mark - Control

- (void)waitUntilFinished
{
    [_messageLoop waitUntilFinished];
}

#pragma mark - KTVVPFrameInput

- (BOOL)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (source == _filters.lastObject)
    {
        if (self.needFlushBeforOutput)
        {
            glFlush();
        }
        [frame lock];
        for (id <KTVVPFrameInput> obj in self.outputs)
        {
            [obj inputFrame:frame fromSource:self];
        }
        [frame unlock];
    }
    else
    {
        [self setupIfNeeded];
        if (_processing)
        {
            NSLog(@"KTVVPSerialPipeline: Frame did drop...");
            return NO;
        }
        _processing = YES;
        [frame lock];
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLDrawing object:frame dropCallback:^(KTVVPMessage * message) {
            KTVVPFrame * object = (KTVVPFrame *)message.object;
            [object unlock];
        }]];
    }
    return YES;
}

#pragma mark - KTVVPMessageLoopDelegate

- (void)messageLoop:(KTVVPMessageLoop *)messageLoop processingMessage:(KTVVPMessage *)message
{
    if (message.type == KTVVPMessageTypeOpenGLSetupContext)
    {
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                           sharegroup:self.context.mainGLContext.sharegroup];
        KTVVPSetCurrentGLContextIfNeeded(_glContext);
        _framePool = [[KTVVPFramePool alloc] init];
        _frameUploader = [[KTVVPFrameUploader alloc] initWithGLContext:_glContext];
        
        NSMutableArray <__kindof KTVVPFilter *> * filters = [NSMutableArray arrayWithCapacity:self.filterClasses.count];
        __kindof KTVVPFilter * lastFilter = nil;
        for (NSInteger i = 0; i < self.filterClasses.count; i++)
        {
            Class filterClass = [self.filterClasses objectAtIndex:i];
            __kindof KTVVPFilter * obj = [filterClass alloc];
            obj = [obj initWithGLContext:_glContext
                               framePool:_framePool
                           frameUploader:_frameUploader];
            if (_filterConfigurationCallback)
            {
                _filterConfigurationCallback(obj, i);
            }
            lastFilter.output = obj;
            lastFilter = obj;
            [filters addObject:obj];
        }
        lastFilter.output = self;
        _filters = filters;
    }
    else if (message.type == KTVVPMessageTypeOpenGLDrawing)
    {
        KTVVPFrame * frame = (KTVVPFrame *)message.object;
        if (frame)
        {
            KTVVPSetCurrentGLContextIfNeeded(_glContext);
            [_filters.firstObject inputFrame:frame fromSource:self];
            [frame unlock];
            _processing = NO;
        }
    }
    else if (message.type == KTVVPMessageTypeOpenGLFinish)
    {
        glFinish();
    }
}

@end
