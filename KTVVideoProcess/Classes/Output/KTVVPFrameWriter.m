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

@property (nonatomic, assign) NSTimeInterval delayIntervalInternal;

@property (nonatomic, strong) AVAssetWriter * assetWriter;
@property (nonatomic, strong) AVAssetWriterInput * assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor * assetWriterInputPixelBufferAdaptor;

@property (nonatomic, strong) NSMutableArray <KTVVPFrame *> * frameQueue;
@property (nonatomic, strong) KTVVPTimeComponents * timeComponents;
@property (nonatomic, assign) CMTime videoStartTime;

@property (nonatomic, strong) KTVVPMessageLoop * messageLoop;
@property (nonatomic, assign) BOOL didCallStartRecording;
@property (nonatomic, assign) BOOL didClosed;

@end

@implementation KTVVPFrameWriter

- (instancetype)init
{
    if (self = [super init])
    {
        _outputFileType = AVFileTypeQuickTimeMovie;
        _videoOutputCodec = AVVideoCodecH264;
        _videoOutputScalingMode = AVVideoScalingModeResizeAspectFill;
        _videoStartTime = kCMTimeInvalid;
        _frameQueue = [NSMutableArray array];
        _timeComponents = [[KTVVPTimeComponents alloc] init];
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
        [self.messageLoop setFinishedCallback:^(KTVVPMessageLoop *messageLoop) {
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
    
    _messageLoop = [[KTVVPMessageLoop alloc] initWithIdentify:@"FrameWriter" delegate:self];
    [_messageLoop run];
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterReset object:nil]];
}

- (void)finish
{
    if (!_didCallStartRecording)
    {
        return;
    }
    if (_didClosed)
    {
        return;
    }
    _didClosed = YES;
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterFinish object:nil] delay:_delayIntervalInternal];
}

- (void)cancel
{
    if (!_didCallStartRecording)
    {
        return;
    }
    if (_didClosed)
    {
        return;
    }
    _didClosed = YES;
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterCancel object:nil] delay:_delayIntervalInternal];
}


#pragma mark - KTVVPFrameInput

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (!_didCallStartRecording)
    {
        return;
    }
    if (_didClosed)
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
        if (_startCallback)
        {
            _startCallback(_error ? NO : YES);
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
            if (_cancelCallback)
            {
                _cancelCallback(YES);
            }
        }
        else
        {
            if (_cancelCallback)
            {
                _cancelCallback(NO);
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
    
    if (_videoOutputSettings)
    {
        NSMutableDictionary * videoOutputSettings = [NSMutableDictionary dictionaryWithDictionary:_videoOutputSettings];
        
        NSString * codec = [videoOutputSettings objectForKey:AVVideoCodecKey];
        if (codec) {
            _videoOutputCodec = codec;
        } else {
            [videoOutputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        }
        NSString * scalingMode = [videoOutputSettings objectForKey:AVVideoScalingModeKey];
        if (scalingMode) {
            _videoOutputScalingMode = scalingMode;
        } else {
            [videoOutputSettings setObject:AVVideoScalingModeResizeAspectFill forKey:AVVideoScalingModeKey];
        }
        KTVVPSize size = KTVVPSizeZero();
        NSNumber * width = [videoOutputSettings objectForKey:AVVideoWidthKey];
        if (width) {
            size.width = width.intValue;
        } else {
            [videoOutputSettings setObject:@(_videoOutputSize.width) forKey:AVVideoWidthKey];
        }
        NSNumber * height = [videoOutputSettings objectForKey:AVVideoHeightKey];
        if (height) {
            size.height = height.intValue;
        } else {
            [videoOutputSettings setObject:@(_videoOutputSize.height) forKey:AVVideoHeightKey];
        }
        _videoOutputSize = size;
    }
    else
    {
        _videoOutputSettings = @{AVVideoCodecKey : _videoOutputCodec,
                                 AVVideoScalingModeKey : _videoOutputScalingMode,
                                 AVVideoWidthKey : @(_videoOutputSize.width),
                                 AVVideoHeightKey : @(_videoOutputSize.height)};
    }
    if (KTVVPSizeEqualToSize(_videoOutputSize, KTVVPSizeZero()))
    {
        NSString * domain = @"video output size can't be zero";
        NSAssert(NO, domain);
        _error = [NSError errorWithDomain:domain code:-1 userInfo:nil];
        return;
    }
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:_videoOutputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = NO;
    _assetWriterVideoInput.transform = _videoOutputTransform;
    
    if (_videoSourcePixelBufferAttributes)
    {
        NSMutableDictionary * videoSourcePixelBufferAttributes = [NSMutableDictionary dictionaryWithDictionary:_videoSourcePixelBufferAttributes];

        NSNumber * format = [videoSourcePixelBufferAttributes objectForKey:(id)kCVPixelBufferPixelFormatTypeKey];
        if (format) {
            _videoSourcePixelFormat = format.integerValue;
        } else {
            [videoSourcePixelBufferAttributes setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        }

        KTVVPSize size = KTVVPSizeZero();
        NSNumber * width = [videoSourcePixelBufferAttributes objectForKey:(id)kCVPixelBufferWidthKey];
        if (width) {
            size.width = width.intValue;
        } else {
            [videoSourcePixelBufferAttributes setObject:@(_videoSourceSize.width) forKey:(id)kCVPixelBufferWidthKey];
        }
        NSNumber * height = [videoSourcePixelBufferAttributes objectForKey:(id)kCVPixelBufferHeightKey];
        if (height) {
            size.height = height.intValue;
        } else {
            [videoSourcePixelBufferAttributes setObject:@(_videoSourceSize.height) forKey:(id)kCVPixelBufferHeightKey];
        }
        _videoSourceSize = size;
    }
    else
    {
        _videoSourcePixelBufferAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                              (id)kCVPixelBufferWidthKey : @(_videoOutputSize.width),
                                              (id)kCVPixelBufferHeightKey : @(_videoOutputSize.height)};
    }
    if (KTVVPSizeEqualToSize(_videoSourceSize, KTVVPSizeZero()))
    {
        NSString * domain = @"video source size can't be zero";
        NSAssert(NO, domain);
        _error = [NSError errorWithDomain:domain code:-1 userInfo:nil];
        return;
    }
    _assetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:_videoSourcePixelBufferAttributes];
    [_assetWriter addInput:_assetWriterVideoInput];
    
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
