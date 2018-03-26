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

@property (nonatomic, strong) NSArray <KTVVPFilter *> * filters;
@property (nonatomic, strong) KTVVPMessageLoop * messageLoop;

@end

@implementation KTVVPSerialPipeline

- (void)setupInternal
{
    _messageLoop = [[KTVVPMessageLoop alloc] init];
    _messageLoop.delegate = self;
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLSetupContext object:nil]];
    [_messageLoop run];
}


#pragma mark - KTVVPFrameInput

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (source == self.filters.lastObject)
    {
        [self outputFrame:frame];
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
        [self.messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLDrawing object:frame]];
    }
}


#pragma mark - KTVVPMessageLoopDelegate

- (void)messageLoop:(KTVVPMessageLoop *)messageLoop processingMessage:(KTVVPMessage *)message
{
    if (message.type == KTVVPMessageTypeOpenGLSetupContext)
    {
        [self.context setGLContextForCurrentThreadIfNeeded];
        
        NSMutableArray * filters = [NSMutableArray arrayWithCapacity:self.filterClasses.count];
        __kindof KTVVPFilter * lastFilter = nil;
        for (Class filterClass in self.filterClasses)
        {
            __kindof KTVVPFilter * obj = [filterClass alloc];
            obj = [obj initWithContext:self.context];
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
            [self.context setGLContextForCurrentThreadIfNeeded];
            
            [_filters.firstObject inputFrame:frame fromSource:self];
            [frame unlock];
            
            _processing = NO;
        }
    }
}

@end
