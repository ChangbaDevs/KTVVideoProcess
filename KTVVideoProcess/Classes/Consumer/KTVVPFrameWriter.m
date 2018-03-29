//
//  KTVVPFrameWriter.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/21.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameWriter.h"
#import "KTVVPMessageLoop.h"
#import "KTVVPTimeComponents.h"

typedef NS_ENUM(NSUInteger, KTVVPMessageTypeWriter)
{
    KTVVPMessageTypeWriterIdle,
    KTVVPMessageTypeWriterReset,
    KTVVPMessageTypeWriterDrop,
    KTVVPMessageTypeWriterInsert,
    KTVVPMessageTypeWriterAppending,
    KTVVPMessageTypeWriterFinish,
    KTVVPMessageTypeWriterCancel,
};

@interface KTVVPFrameWriter () <KTVVPMessageLoopDelegate>

@property (nonatomic, strong) AVAssetWriter * assetWriter;
@property (nonatomic, strong) AVAssetWriterInput * assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor * assetWriterInputPixelBufferAdaptor;

@property (nonatomic, strong) NSMutableArray <KTVVPFrame *> * frameQueue;
@property (nonatomic, assign) NSTimeInterval delayIntervalInternal;
@property (nonatomic, strong) KTVVPTimeComponents * timeComponents;

@property (nonatomic, strong) KTVVPMessageLoop * messageLoop;
@property (nonatomic, assign) BOOL didCallStartRecording;

@end

@implementation KTVVPFrameWriter

- (instancetype)initWithContext:(KTVVPContext *)context videoSize:(KTVVPGLSize)videoSize
{
    if (self = [super init])
    {
        if (videoSize.width == 0 || videoSize.height == 0)
        {
            NSAssert(NO, @"video size can't be zero");
        }
        _context = context;
        _videoSize = videoSize;
        _outputFileType = AVFileTypeQuickTimeMovie;
        _videoOutputSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                 AVVideoWidthKey : @(_videoSize.width),
                                 AVVideoHeightKey : @(_videoSize.height)};
        _videoSourcePixelBufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                              (id)kCVPixelBufferWidthKey : @(_videoSize.width),
                                              (id)kCVPixelBufferHeightKey : @(_videoSize.height)};
        _videoStartTime = kCMTimeInvalid;
        
        _messageLoop = [[KTVVPMessageLoop alloc] init];
        _messageLoop.delegate = self;
        [_messageLoop run];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    if (_didCallStartRecording)
    {
        AVAssetWriter * assetWriter = _assetWriter;
        AVAssetWriterInput * assetWriterVideoInput = _assetWriterVideoInput;
        NSMutableArray <KTVVPFrame *> * frameQueue = _frameQueue;
        [self.messageLoop setThreadDidFiniahedCallback:^(KTVVPMessageLoop *messageLoop) {
            if (assetWriter.status == AVAssetWriterStatusWriting)
            {
                [assetWriterVideoInput markAsFinished];
                [assetWriter cancelWriting];
            }
            [frameQueue enumerateObjectsUsingBlock:^(KTVVPFrame * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj unlock];
            }];
        }];
    }
    [_messageLoop stop];
    _messageLoop = nil;
}


#pragma mark - Control

- (void)start
{
    if (_didCallStartRecording)
    {
        return;
    }
    _didCallStartRecording = YES;
    _delayIntervalInternal = _delayInterval;
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterReset object:nil]];
}

- (void)finish
{
    if (!_didCallStartRecording)
    {
        return;
    }
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterFinish object:nil] delay:_delayIntervalInternal];
}

- (void)cancel
{
    if (!_didCallStartRecording)
    {
        return;
    }
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterCancel object:nil] delay:_delayIntervalInternal];
}


#pragma mark - KTVVPFrameInput

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (!_didCallStartRecording)
    {
        return;
    }
    if (CMTIME_IS_INVALID(frame.timeStamp))
    {
        NSAssert(NO, @"timeStamp must a vaild CMTime value");
        return;
    }
    [frame lock];
    if (_paused)
    {
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterDrop object:frame dropCallback:^(KTVVPMessage * message) {
            KTVVPFrame * object = (KTVVPFrame *)message.object;
            [object unlock];
        }] delay:_delayIntervalInternal];
    }
    else
    {
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterInsert object:frame dropCallback:^(KTVVPMessage * message) {
            KTVVPFrame * object = (KTVVPFrame *)message.object;
            [object unlock];
        }]];
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterAppending object:nil] delay:_delayIntervalInternal];
    }
}


#pragma mark - KTVVPMessageLoopDelegate

- (void)messageLoop:(KTVVPMessageLoop *)messageLoop processingMessage:(KTVVPMessage *)message
{
    if (message.type == KTVVPMessageTypeWriterReset)
    {
        [self setupAssetWriter];
        if (_startedCallback)
        {
            _startedCallback(_error ? NO : YES);
        }
    }
    else if (message.type == KTVVPMessageTypeWriterDrop)
    {
        KTVVPFrame * frame = (KTVVPFrame *)message.object;
        [_timeComponents putDroppedTimeStamp:frame.timeStamp];
        [frame unlock];
    }
    else if (message.type == KTVVPMessageTypeWriterInsert)
    {
        KTVVPFrame * frame = (KTVVPFrame *)message.object;
        [self insertFrameInOrder:frame];
    }
    else if (message.type == KTVVPMessageTypeWriterAppending)
    {
        [self processFristFrame];
    }
    else if (message.type == KTVVPMessageTypeWriterFinish)
    {
        if (_assetWriter.status == AVAssetWriterStatusWriting)
        {
            [_assetWriterVideoInput markAsFinished];
            [_assetWriter finishWritingWithCompletionHandler:^{
                if (_finishedCallback)
                {
                    _finishedCallback(YES);
                }
            }];
        }
        else
        {
            if (_finishedCallback)
            {
                _finishedCallback(NO);
            }
        }
    }
    else if (message.type == KTVVPMessageTypeWriterCancel)
    {
        if (_assetWriter.status == AVAssetWriterStatusWriting)
        {
            [_assetWriterVideoInput markAsFinished];
            [_assetWriter cancelWriting];
            if (_canceledCallback)
            {
                _canceledCallback(YES);
            }
        }
        else
        {
            if (_canceledCallback)
            {
                _canceledCallback(NO);
            }
        }
    }
}


#pragma mark - Setup

- (void)setupAssetWriter
{
    if (!_outputFileURL || !_outputFileType)
    {
        NSString * domain = @"outputFileURL and outputFileType can't be nil";
        NSAssert(NO, domain);
        _error = [NSError errorWithDomain:domain code:-1 userInfo:nil];
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_outputFileURL.path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:_outputFileURL.path error:nil];
    }
    
    NSError * error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:_outputFileURL fileType:_outputFileType error:&error];
    if (error)
    {
        _error = error;
        return;
    }
    
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:_videoOutputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = NO;
    _assetWriterVideoInput.transform = _videoTransform;
    _assetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:_videoSourcePixelBufferAttributes];
    [_assetWriter addInput:_assetWriterVideoInput];
    
    _frameQueue = [NSMutableArray array];
    _timeComponents = [[KTVVPTimeComponents alloc] init];
    
    if (![_assetWriter startWriting])
    {
        NSString * domain = @"Start writing failed";
        _error = [NSError errorWithDomain:domain code:-2 userInfo:nil];
    }
}


#pragma mark - Frame Queue

- (void)processFristFrame
{
    KTVVPFrame * frame = [self getFirstFrame];
    if (!frame)
    {
        return;
    }
    if (_assetWriter.status != AVAssetWriterStatusWriting)
    {
        [frame unlock];
        return;
    }
    if (!_assetWriterVideoInput.readyForMoreMediaData)
    {
        [frame unlock];
        return;
    }
    [_timeComponents putCurrentTimeStamp:frame.timeStamp];
    CMTime timeStamp = _timeComponents.timeStamp;
    if (CMTimeCompare(timeStamp, _timeComponents.previousTimeStamp) < 0)
    {
        NSLog(@"KTVVPFrameWriter Frame time is less than previous time.");
        [frame unlock];
        return;
    }
    if (CMTIME_IS_INVALID(_videoStartTime))
    {
        [_assetWriter startSessionAtSourceTime:timeStamp];
        _videoStartTime = timeStamp;
    }
    CVPixelBufferRef pixelBuffer = frame.corePixelBuffer;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:timeStamp];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [frame unlock];
}

- (void)insertFrameInOrder:(KTVVPFrame *)frame
{
    [_frameQueue addObject:frame];
    [_frameQueue sortUsingComparator:^NSComparisonResult(KTVVPFrame * obj1, KTVVPFrame * obj2) {
        if (CMTimeCompare(obj1.timeStamp, obj2.timeStamp) > 0)
        {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
}

- (KTVVPFrame *)getFirstFrame
{
    KTVVPFrame * frame = _frameQueue.firstObject;
    [_frameQueue removeObject:frame];
    return frame;
}

@end
