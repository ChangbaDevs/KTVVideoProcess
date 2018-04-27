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
    KTVVPMessageTypeWriterVdieoFrameDrop,
    KTVVPMessageTypeWriterVdieoFrameInsert,
    KTVVPMessageTypeWriterVideoFrameAppending,
    KTVVPMessageTypeWriterAudioSampleBufferDrop,
    KTVVPMessageTypeWriterAudioSampleBufferAppending,
    KTVVPMessageTypeWriterFinish,
    KTVVPMessageTypeWriterCancel,
};

@interface KTVVPFrameWriter () <KTVVPMessageLoopDelegate>

@property (nonatomic, assign) NSTimeInterval videoEncodeDelayIntervalInternal;

@property (nonatomic, strong) AVAssetWriter * assetWriter;
@property (nonatomic, assign) CMTime assetWriterStartTime;
@property (nonatomic, strong) AVAssetWriterInput * assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInput * assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor * assetWriterInputPixelBufferAdaptor;

@property (nonatomic, strong) KTVVPTimeComponents * audioTimeComponents;
@property (nonatomic, strong) KTVVPTimeComponents * videoTimeComponents;

@property (nonatomic, strong) NSMutableArray <KTVVPFrame *> * frameQueue;
@property (nonatomic, strong) KTVVPMessageLoop * messageLoop;
@property (nonatomic, assign) BOOL didCallStartRecording;
@property (nonatomic, assign) BOOL didClosed;

@end

@implementation KTVVPFrameWriter

- (instancetype)init
{
    if (self = [super init])
    {
        _outputFileType = AVFileTypeMPEG4;
        _videoOutputScalingMode = AVVideoScalingModeResizeAspectFill;
        _assetWriterStartTime = kCMTimeInvalid;
        _videoTimeComponents = [[KTVVPTimeComponents alloc] init];
        _audioTimeComponents = [[KTVVPTimeComponents alloc] init];
        _frameQueue = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    if (_didCallStartRecording)
    {
        AVAssetWriter * assetWriter = _assetWriter;
        AVAssetWriterInput * assetWriterAudioInput = _assetWriterAudioInput;
        AVAssetWriterInput * assetWriterVideoInput = _assetWriterVideoInput;
        NSMutableArray <KTVVPFrame *> * frameQueue = _frameQueue;
        [self.messageLoop setFinishedCallback:^(KTVVPMessageLoop *messageLoop) {
            if (assetWriter.status == AVAssetWriterStatusWriting)
            {
                [assetWriterAudioInput markAsFinished];
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
    _videoEncodeDelayIntervalInternal = _videoEncodeDelayInterval;
    
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
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterFinish object:nil] delay:_videoEncodeDelayIntervalInternal];
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
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterCancel object:nil] delay:_videoEncodeDelayIntervalInternal];
}


#pragma mark - Setter/Getter

- (NSTimeInterval)duration
{
    CMTime duration = _videoTimeComponents.duration;
    if (CMTIME_IS_INVALID(duration))
    {
        return 0;
    }
    return CMTimeGetSeconds(duration);
}


#pragma mark - KTVVPAudioInput

- (void)inputAudioSampleBuffer:(KTVVPAudioSampleBuffer *)audioSampleBuffer fromSource:(id)source
{
    if (!_didCallStartRecording)
    {
        return;
    }
    if (_didClosed)
    {
        return;
    }
    if (CMTIME_IS_INVALID(audioSampleBuffer.timeStamp))
    {
        NSAssert(NO, @"timeStamp must a vaild CMTime value");
        return;
    }
    if (_paused)
    {
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterAudioSampleBufferDrop
                                                        object:audioSampleBuffer]];
    }
    else
    {
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterAudioSampleBufferAppending
                                                        object:audioSampleBuffer]];
    }
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
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterVdieoFrameDrop object:frame dropCallback:^(KTVVPMessage * message) {
            KTVVPFrame * object = (KTVVPFrame *)message.object;
            [object unlock];
        }] delay:_videoEncodeDelayIntervalInternal];
    }
    else
    {
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterVdieoFrameInsert object:frame dropCallback:^(KTVVPMessage * message) {
            KTVVPFrame * object = (KTVVPFrame *)message.object;
            [object unlock];
        }]];
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterVideoFrameAppending object:nil] delay:_videoEncodeDelayIntervalInternal];
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
    else if (message.type == KTVVPMessageTypeWriterVdieoFrameDrop)
    {
        KTVVPFrame * frame = (KTVVPFrame *)message.object;
        [_videoTimeComponents putDroppedTimeStamp:frame.timeStamp];
        [frame unlock];
    }
    else if (message.type == KTVVPMessageTypeWriterVdieoFrameInsert)
    {
        KTVVPFrame * frame = (KTVVPFrame *)message.object;
        [self insertVideoFrameInOrder:frame];
    }
    else if (message.type == KTVVPMessageTypeWriterVideoFrameAppending)
    {
        [self processFristVideoFrame];
    }
    else if (message.type == KTVVPMessageTypeWriterAudioSampleBufferDrop)
    {
        KTVVPAudioSampleBuffer * obj = (KTVVPAudioSampleBuffer *)message.object;
        [_audioTimeComponents putDroppedTimeStamp:obj.timeStamp];
    }
    else if (message.type == KTVVPMessageTypeWriterAudioSampleBufferAppending)
    {
        KTVVPAudioSampleBuffer * obj = (KTVVPAudioSampleBuffer *)message.object;
        [self processAudioSampleBuffer:obj];
    }
    else if (message.type == KTVVPMessageTypeWriterFinish)
    {
        if (_assetWriter.status == AVAssetWriterStatusWriting)
        {
            [_assetWriterAudioInput markAsFinished];
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
            [_assetWriterAudioInput markAsFinished];
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


#pragma mark - Setup AssetWriter

- (void)setupAssetWriter
{
    if (!_outputFileURL || !_outputFileType)
    {
        NSString * domain = @"outputFileURL and outputFileType can't be nil";
        NSAssert(NO, domain);
        _error = [NSError errorWithDomain:domain code:-1 userInfo:nil];
        return;
    }
    if (KTVVPSizeEqualToSize(_videoOutputSize, KTVVPSizeZero()))
    {
        NSString * domain = @"video output size can't be zero";
        NSAssert(NO, domain);
        _error = [NSError errorWithDomain:domain code:-1 userInfo:nil];
        return;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:_outputFileURL.path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:_outputFileURL.path
                                                   error:nil];
    }
    
    NSError * error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:_outputFileURL
                                             fileType:_outputFileType
                                                error:&error];
    if (error)
    {
        _error = error;
        return;
    }
    
    if (!_videoOutputSettings)
    {
        NSMutableDictionary * outputSettings = [[NSMutableDictionary alloc] init];
        [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        [outputSettings setObject:_videoOutputScalingMode forKey:AVVideoScalingModeKey];
        [outputSettings setObject:@(_videoOutputSize.width) forKey:AVVideoWidthKey];
        [outputSettings setObject:@(_videoOutputSize.height) forKey:AVVideoHeightKey];
        _videoOutputSettings = outputSettings;
    }
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                outputSettings:_videoOutputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = _videoOutputTransform;
    
    if (!_videoSourcePixelBufferAttributes)
    {
        NSMutableDictionary * outputSettings = [[NSMutableDictionary alloc] init];
        [outputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [outputSettings setObject:@(_videoOutputSize.width) forKey:(id)kCVPixelBufferWidthKey];
        [outputSettings setObject:@(_videoOutputSize.height) forKey:(id)kCVPixelBufferHeightKey];
        _videoSourcePixelBufferAttributes = outputSettings;
    }
    _assetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput
                                                                                                           sourcePixelBufferAttributes:_videoSourcePixelBufferAttributes];
    [_assetWriter addInput:_assetWriterVideoInput];
    
    if (_audioEnable)
    {
        if (!_audioOutputSettings)
        {
            AudioChannelLayout acl;
            bzero(&acl, sizeof(acl));
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
            NSData * channelLayout = [NSData dataWithBytes:&acl length:sizeof(acl)];
            NSMutableDictionary * outputSettings = [[NSMutableDictionary alloc] init];
            [outputSettings setObject:@(kAudioFormatMPEG4AAC) forKey:AVFormatIDKey];
            [outputSettings setObject:@(44100) forKey:AVSampleRateKey];
            [outputSettings setObject:@(2) forKey:AVNumberOfChannelsKey];
            [outputSettings setObject:channelLayout forKey:AVChannelLayoutKey];
            _audioOutputSettings = outputSettings;
        }
        _assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                                    outputSettings:_audioOutputSettings];
        _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        [_assetWriter addInput:_assetWriterAudioInput];
    }
    
    if (![_assetWriter startWriting])
    {
        NSString * domain = @"Start writing failed";
        _error = [NSError errorWithDomain:domain code:-2 userInfo:nil];
        return;
    }
}


#pragma mark - Audio Process

- (void)processAudioSampleBuffer:(KTVVPAudioSampleBuffer *)audioSampleBuufer
{
    if (_assetWriter.status != AVAssetWriterStatusWriting)
    {
        return;
    }
    if (!_assetWriterAudioInput.readyForMoreMediaData)
    {
        return;
    }
    [_audioTimeComponents putCurrentTimeStamp:audioSampleBuufer.timeStamp];
    CMTime timeStamp = _audioTimeComponents.timeStamp;
    if (CMTimeCompare(timeStamp, _audioTimeComponents.previousTimeStamp) < 0)
    {
        NSLog(@"KTVVPFrameWriter AduioSampleBuffer time is less than previous time.");
        return;
    }
    if (CMTIME_IS_INVALID(_assetWriterStartTime))
    {
        NSLog(@"Set start time by audio track");
        [_assetWriter startSessionAtSourceTime:timeStamp];
        _assetWriterStartTime = timeStamp;
    }
    CMSampleBufferRef sampleBuffer = audioSampleBuufer.sampleBuffer;
    CMTime sourcePresentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(audioSampleBuufer.sampleBuffer);
    CMTime adjustPresentationTimeStamp = _audioTimeComponents.timeStamp;
    if (CMTimeCompare(sourcePresentationTimeStamp, adjustPresentationTimeStamp) != 0)
    {
        NSLog(@"pts not equal, %f, %f",
              CMTimeGetSeconds(sourcePresentationTimeStamp),
              CMTimeGetSeconds(adjustPresentationTimeStamp));
    }
    [_assetWriterAudioInput appendSampleBuffer:sampleBuffer];
}


#pragma mark - Video Process

- (void)processFristVideoFrame
{
    KTVVPFrame * frame = [self getFirstVideoFrame];
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
    [_videoTimeComponents putCurrentTimeStamp:frame.timeStamp];
    CMTime timeStamp = _videoTimeComponents.timeStamp;
    if (CMTimeCompare(timeStamp, _videoTimeComponents.previousTimeStamp) < 0)
    {
        NSLog(@"KTVVPFrameWriter Frame time is less than previous time.");
        [frame unlock];
        return;
    }
    if (CMTIME_IS_INVALID(_assetWriterStartTime))
    {
        NSLog(@"Set start time by video track");
        [_assetWriter startSessionAtSourceTime:timeStamp];
        _assetWriterStartTime = timeStamp;
    }
    CVPixelBufferRef pixelBuffer = frame.corePixelBuffer;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:timeStamp];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [frame unlock];
}

- (void)insertVideoFrameInOrder:(KTVVPFrame *)frame
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

- (KTVVPFrame *)getFirstVideoFrame
{
    KTVVPFrame * frame = _frameQueue.firstObject;
    [_frameQueue removeObject:frame];
    return frame;
}

@end
