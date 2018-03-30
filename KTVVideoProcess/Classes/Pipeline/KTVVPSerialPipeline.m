//
//  KTVVPSerialPipeline.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/23.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPSerialPipeline.h"
#import "KTVVPPipelinePrivate.h"
#import "KTVVPFilter.h"
#import "KTVVPMessageLoop.h"

@interface KTVVPSerialPipeline () <KTVVPPipelinePrivate, KTVVPMessageLoopDelegate>

@property (nonatomic, strong) EAGLContext * glContext;
@property (nonatomic, strong) KTVVPFramePool * framePool;
@property (nonatomic, strong) KTVVPFrameUploader * frameUploader;

@property (nonatomic, strong) NSArray <KTVVPFilter *> * filters;
@property (nonatomic, strong) KTVVPMessageLoop * messageLoop;

@end

@implementation KTVVPSerialPipeline

- (instancetype)initWithContext:(KTVVPContext *)context
                  filterClasses:(NSArray <Class> *)filterClasses
{
    if (self = [super initWithContext:context
                        filterClasses:filterClasses])
    {
        NSLog(@"%s", __func__);
        _pipelineIndex = 0;
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
    [_messageLoop run];
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLSetupContext object:nil]];
}


#pragma mark - KTVVPFrameInput

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (source == self.filters.lastObject)
    {
        NSLog(@"KTVVPSerialPipeline: end process frame.");
        
        [self outputFrame:frame];
        
        NSLog(@"KTVVPSerialPipeline: end output frame.");
    }
    else
    {
        [self setupIfNeeded];
        
        if (_processing)
        {
            NSLog(@"KTVVPSerialPipeline: Frame did drop...");
            return;
        }
        _processing = YES;
        
        [frame lock];
        [self.messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLDrawing object:frame dropCallback:^(KTVVPMessage * message) {
            KTVVPFrame * object = (KTVVPFrame *)message.object;
            [object unlock];
        }]];
    }
}


#pragma mark - KTVVPMessageLoopDelegate

- (void)messageLoop:(KTVVPMessageLoop *)messageLoop processingMessage:(KTVVPMessage *)message
{
    if (message.type == KTVVPMessageTypeOpenGLSetupContext)
    {
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                           sharegroup:self.context.mainGLContext.sharegroup];
        [_glContext setCurrentIfNeeded];
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
            if (self.filterConfigurationCallback)
            {
                self.filterConfigurationCallback(obj, i, _pipelineIndex);
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
            NSLog(@"KTVVPSerialPipeline: begin process frame.");
            
            [_glContext setCurrentIfNeeded];
            
            [_filters.firstObject inputFrame:frame fromSource:self];
            [frame unlock];
            
            _processing = NO;
        }
    }
}

@end
