//
//  KTVVPFrameWriter.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/21.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameWriter.h"
#import "KTVVPMessageLoop.h"
#import "KTVVPTimeComponents.h"
#import "KTVVPPixelBufferPool.h"
#import "KTVVPLog.h"

typedef NS_ENUM(NSUInteger, KTVVPMessageTypeWriter) {
    KTVVPMessageTypeWriterIdle,
    KTVVPMessageTypeWriterReset,
    KTVVPMessageTypeWriterFrameDrop,
    KTVVPMessageTypeWriterFrameInsert,
    KTVVPMessageTypeWriterFrameAppending,
    KTVVPMessageTypeWriterSampleDrop,
    KTVVPMessageTypeWriterSampleAppending,
    KTVVPMessageTypeWriterFinish,
    KTVVPMessageTypeWriterCancel,
};

@interface KTVVPFrameWriter () <KTVVPMessageLoopDelegate>

{
    CMFormatDescriptionRef _audioFormatDescription;
}

@property (nonatomic, assign) NSTimeInterval videoEncodeDelayIntervalInternal;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, assign) CMTime assetWriterStartTime;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *assetWriterInputPixelBufferAdaptor;

@property (nonatomic, strong) KTVVPTimeComponents *audioTimeComponents;
@property (nonatomic, strong) KTVVPTimeComponents *videoTimeComponents;

@property (nonatomic, strong) NSMutableArray <KTVVPFrame *> *frameQueue;
@property (nonatomic, strong) KTVVPPixelBufferPool *pixelBufferPool;
@property (nonatomic, strong) KTVVPMessageLoop *messageLoop;
@property (nonatomic, assign) BOOL didCallStartRecording;
@property (nonatomic, assign) BOOL didClosed;

@property (nonatomic, assign) long long numberOfFrames;
@property (nonatomic, assign) long long numberOfSamples;

@end

@implementation KTVVPFrameWriter

- (instancetype)init
{
    if (self = [super init]) {
        _outputFileType = AVFileTypeMPEG4;
        _minimumNumberOfFrames = 1;
        _minimumNumberOfSamples = 1;
        _videoOutputScalingMode = AVVideoScalingModeResizeAspect;
        _videoOutputTransform = CGAffineTransformIdentity;
        _videoOutputBitRate = 0;
        _videoOutputMaxKeyFrameInterval = 0;
        _videoOutputMaxKeyFrameIntervalDuration = kCMTimeZero;
        _videoOutputAllowFrameReordering = NO;
        _assetWriterStartTime = kCMTimeInvalid;
        _videoTimeComponents = [[KTVVPTimeComponents alloc] init];
        _audioTimeComponents = [[KTVVPTimeComponents alloc] init];
        _frameQueue = [NSMutableArray array];
        _audioFormatDescription = NULL;
    }
    return self;
}

- (void)dealloc
{
    KTVVPLog(@"%s", __func__);
    if (_audioFormatDescription) {
        CFRelease(_audioFormatDescription);
        _audioFormatDescription = NULL;
    }
    if (_didCallStartRecording) {
        AVAssetWriter *assetWriter = _assetWriter;
        AVAssetWriterInput *assetWriterAudioInput = _assetWriterAudioInput;
        AVAssetWriterInput *assetWriterVideoInput = _assetWriterVideoInput;
        NSMutableArray <KTVVPFrame *> *frameQueue = _frameQueue;
        [_messageLoop setStopCallback:^(KTVVPMessageLoop *messageLoop) {
            if (assetWriter.status == AVAssetWriterStatusWriting) {
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

- (void)start
{
    if (_didCallStartRecording) {
        return;
    }
    _didCallStartRecording = YES;
    _videoEncodeDelayIntervalInternal = _videoEncodeDelayInterval;
    
    _messageLoop = [[KTVVPMessageLoop alloc] initWithIdentify:@"FrameWriter" delegate:self];
    [_messageLoop start];
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterReset object:nil]];
}

- (void)finish
{
    if (!_didCallStartRecording) {
        return;
    }
    if (_didClosed) {
        return;
    }
    _didClosed = YES;
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterFinish object:nil] delay:_videoEncodeDelayIntervalInternal];
}

- (void)cancel
{
    if (!_didCallStartRecording) {
        return;
    }
    if (_didClosed) {
        return;
    }
    _didClosed = YES;
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterCancel object:nil] delay:_videoEncodeDelayIntervalInternal];
}

- (void)waitUntilFinished
{
    [_messageLoop waitUntilFinished];
}

#pragma mark - Setter/Getter

- (CMTime)duration
{
    CMTime duration = _videoTimeComponents.duration;
    if (CMTIME_IS_INVALID(duration)) {
        return kCMTimeZero;
    }
    return duration;
}

#pragma mark - KTVVPSampleInput

- (BOOL)inputSample:(KTVVPSample *)sample fromSource:(id)source
{
    if (!_didCallStartRecording) {
        return NO;
    }
    if (_didClosed) {
        return NO;
    }
    if (CMTIME_IS_INVALID(sample.timeStamp)) {
        NSAssert(NO, @"timeStamp must a vaild CMTime value");
        return NO;
    }
    if (_paused) {
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterSampleDrop
                                                        object:sample]];
    } else {
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterSampleAppending
                                                        object:sample]];
    }
    return YES;
}

#pragma mark - KTVVPFrameInput

- (BOOL)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (!_didCallStartRecording) {
        return NO;
    }
    if (_didClosed) {
        return NO;
    }
    if (CMTIME_IS_INVALID(frame.timeStamp)) {
        NSAssert(NO, @"timeStamp must a vaild CMTime value");
        return NO;
    }
    [frame lock];
    if (_paused) {
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterFrameDrop object:frame dropCallback:^(KTVVPMessage *message) {
            KTVVPFrame *object = (KTVVPFrame *)message.object;
            [object unlock];
        }] delay:_videoEncodeDelayIntervalInternal];
    } else {
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterFrameInsert object:frame dropCallback:^(KTVVPMessage *message) {
            KTVVPFrame *object = (KTVVPFrame *)message.object;
            [object unlock];
        }]];
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeWriterFrameAppending object:nil] delay:_videoEncodeDelayIntervalInternal];
    }
    return YES;
}

#pragma mark - KTVVPMessageLoopDelegate

- (void)messageLoop:(KTVVPMessageLoop *)messageLoop processingMessage:(KTVVPMessage *)message
{
    if (message.type == KTVVPMessageTypeWriterReset) {
        [self setupAssetWriter];
        if (_startCallback) {
            _startCallback(_error ? NO : YES);
            _startCallback = nil;
        }
    } else if (message.type == KTVVPMessageTypeWriterFrameDrop) {
        KTVVPFrame *frame = (KTVVPFrame *)message.object;
        [_videoTimeComponents putDroppedTimeStamp:frame.timeStamp];
        [frame unlock];
    } else if (message.type == KTVVPMessageTypeWriterFrameInsert) {
        KTVVPFrame *frame = (KTVVPFrame *)message.object;
        [self insertVideoFrameInOrder:frame];
    } else if (message.type == KTVVPMessageTypeWriterFrameAppending) {
        [self processFristVideoFrame];
    } else if (message.type == KTVVPMessageTypeWriterSampleDrop) {
        KTVVPSample *obj = (KTVVPSample *)message.object;
        [_audioTimeComponents putDroppedTimeStamp:obj.timeStamp];
    } else if (message.type == KTVVPMessageTypeWriterSampleAppending) {
        KTVVPSample *obj = (KTVVPSample *)message.object;
        [self processSample:obj];
    } else if (message.type == KTVVPMessageTypeWriterFinish) {
        BOOL writing = _assetWriter.status == AVAssetWriterStatusWriting;
        BOOL videoValid = _numberOfFrames >= _minimumNumberOfFrames;
        BOOL audioValid = !_audioEnable || (_audioEnable && _numberOfSamples >= _minimumNumberOfSamples);
        BOOL success = writing && videoValid && audioValid;
        if (success) {
            [self processSampleBeforFinished];
            __block BOOL finished = NO;
            NSCondition *condition = [[NSCondition alloc] init];
            [_assetWriterAudioInput markAsFinished];
            [_assetWriterVideoInput markAsFinished];
            [_assetWriter finishWritingWithCompletionHandler:^{
                [condition lock];
                finished = YES;
                [condition broadcast];
                [condition unlock];
            }];
            [condition lock];
            if (!finished) {
                [condition wait];
            }
            [condition unlock];
        } else if (writing) {
            [_assetWriterAudioInput markAsFinished];
            [_assetWriterVideoInput markAsFinished];
            [_assetWriter cancelWriting];
        }
        if (_finishedCallback) {
            _finishedCallback(success);
            _finishedCallback = nil;
        }
        _appendedFrameCallback = nil;
        _appendedSampleCallback = nil;
    } else if (message.type == KTVVPMessageTypeWriterCancel) {
        if (_assetWriter.status == AVAssetWriterStatusWriting) {
            [_assetWriterAudioInput markAsFinished];
            [_assetWriterVideoInput markAsFinished];
            [_assetWriter cancelWriting];
        }
        if (_cancelCallback) {
            _cancelCallback(YES);
            _cancelCallback = nil;
        }
        _appendedFrameCallback = nil;
        _appendedSampleCallback = nil;
    }
}

#pragma mark - Setup AssetWriter

- (void)setupAssetWriter
{
    if (!_outputFileURL || !_outputFileType) {
        NSString *domain = @"outputFileURL and outputFileType can't be nil";
        NSAssert(NO, domain);
        _error = [NSError errorWithDomain:domain code:-1 userInfo:nil];
        return;
    }
    if (KTVVPSizeEqualToSize(_videoOutputSize, KTVVPSizeZero())) {
        NSString *domain = @"video output size can't be zero";
        NSAssert(NO, domain);
        _error = [NSError errorWithDomain:domain code:-1 userInfo:nil];
        return;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:_outputFileURL.path]) {
        [[NSFileManager defaultManager] removeItemAtPath:_outputFileURL.path error:nil];
    }
    
    NSError *error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:_outputFileURL
                                             fileType:_outputFileType
                                                error:&error];
    if (error) {
        _error = error;
        return;
    }
    
    if (!_videoOutputSettings) {
        NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
        [outputSettings setObject:AVVideoCodecTypeH264 forKey:AVVideoCodecKey];
        NSMutableDictionary *compressionProperties = [NSMutableDictionary dictionary];
        if (_videoOutputBitRate > 0) {
            [compressionProperties setObject:@(_videoOutputBitRate) forKey:AVVideoAverageBitRateKey];
        }
        if (_videoOutputMaxKeyFrameInterval > 0) {
            [compressionProperties setObject:@(_videoOutputMaxKeyFrameInterval) forKey:AVVideoMaxKeyFrameIntervalKey];
        }
        if (CMTimeCompare(_videoOutputMaxKeyFrameIntervalDuration, kCMTimeZero) > 0) {
            [compressionProperties setObject:@(CMTimeGetSeconds(_videoOutputMaxKeyFrameIntervalDuration)) forKey:AVVideoMaxKeyFrameIntervalDurationKey];
        }
        [compressionProperties setObject:@(self.videoOutputAllowFrameReordering) forKey:AVVideoAllowFrameReorderingKey];
        if (compressionProperties.count > 0) {
            [outputSettings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
        }
        [outputSettings setObject:_videoOutputScalingMode forKey:AVVideoScalingModeKey];
        [outputSettings setObject:@(_videoOutputSize.width) forKey:AVVideoWidthKey];
        [outputSettings setObject:@(_videoOutputSize.height) forKey:AVVideoHeightKey];
        _videoOutputSettings = outputSettings;
    }
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                outputSettings:_videoOutputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = _videoOutputTransform;
    
    if (!_videoSourcePixelBufferAttributes) {
        NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
        [outputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [outputSettings setObject:@(_videoOutputSize.width) forKey:(id)kCVPixelBufferWidthKey];
        [outputSettings setObject:@(_videoOutputSize.height) forKey:(id)kCVPixelBufferHeightKey];
        _videoSourcePixelBufferAttributes = outputSettings;
    }
    _assetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:_videoSourcePixelBufferAttributes];
    [_assetWriter addInput:_assetWriterVideoInput];
    
    if (_audioEnable) {
        if (!_audioOutputSettings) {
            AudioChannelLayout acl;
            bzero(&acl, sizeof(acl));
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
            NSData *channelLayout = [NSData dataWithBytes:&acl length:sizeof(acl)];
            NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
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
    
    if (![_assetWriter startWriting]) {
        NSString *domain = @"Start writing failed";
        _error = [NSError errorWithDomain:domain code:-2 userInfo:nil];
        return;
    }
}

#pragma mark - Audio Process

- (void)processSample:(KTVVPSample *)sample
{
    if (_assetWriter.status != AVAssetWriterStatusWriting) {
        return;
    }
    if (!_assetWriterAudioInput.readyForMoreMediaData) {
        return;
    }
    [_audioTimeComponents putCurrentTimeStamp:sample.timeStamp];
    CMTime timeStamp = _audioTimeComponents.timeStamp;
    if (CMTimeCompare(timeStamp, _audioTimeComponents.previousTimeStamp) < 0) {
        KTVVPLog(@"KTVVPFrameWriter AduioSampleBuffer time is less than previous time.");
        return;
    }
    if (CMTIME_IS_INVALID(_assetWriterStartTime)) {
        KTVVPLog(@"Video still not ready.");
        return;
    }
    if (CMTimeCompare(timeStamp, _assetWriterStartTime) < 0) {
        KTVVPLog(@"Invaild audio pts.");
        return;
    }
    CMSampleBufferRef sampleBuffer = sample.sampleBuffer;
    CFRetain(sampleBuffer);
    CMTime sourcePresentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (CMTimeCompare(sourcePresentationTimeStamp, timeStamp) != 0) {
        CMSampleBufferRef adjustSampleBuffer;
        CMSampleTimingInfo timingInfo;
        CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timingInfo);
        CMSampleTimingInfo adjustTimingInfo;
        adjustTimingInfo.duration = timingInfo.duration;
        adjustTimingInfo.presentationTimeStamp = timeStamp;
        adjustTimingInfo.decodeTimeStamp = kCMTimeInvalid;
        CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault,
                                              sampleBuffer,
                                              1,
                                              &adjustTimingInfo,
                                              &adjustSampleBuffer);
        CFRelease(sampleBuffer);
        sampleBuffer = adjustSampleBuffer;
    }
    if (!_audioFormatDescription) {
        _audioFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        if (_audioFormatDescription) {
            CFRetain(_audioFormatDescription);
        }
    }
    [self paddingSampleWithDuration:CMTimeSubtract(timeStamp, _assetWriterStartTime)];
    if ([_assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
        if (_appendedSampleCallback) {
            _appendedSampleCallback(sample);
        }
        _numberOfSamples += CMSampleBufferGetNumSamples(sampleBuffer);
    }
    CFRelease(sampleBuffer);
}

- (void)processSampleBeforFinished
{
    if (_audioEnable) {
        [self paddingSampleWithDuration:self.duration];
    }
}

- (int64_t)paddingSampleWithDuration:(CMTime)duration
{
    int64_t placeholderNumberOfSamples = 0;
    if (_audioFormatDescription) {
        long long sampleRate = [[self.audioOutputSettings objectForKey:AVSampleRateKey] longLongValue];
        CMTime currentDuration = CMTimeMake(_numberOfSamples, (int32_t)sampleRate);
        CMTime deltaDuration = CMTimeSubtract(duration, currentDuration);
        CMTime singleDuration = CMTimeMake(1, (int32_t)sampleRate);
        if (CMTimeCompare(deltaDuration, singleDuration) > 0) {
            const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(_audioFormatDescription);
            CMTime placeholderPresentationTimeStamp = CMTimeAdd(_assetWriterStartTime, currentDuration);
            placeholderNumberOfSamples = sampleRate * deltaDuration.value / deltaDuration.timescale;
            long long dataSize = placeholderNumberOfSamples * asbd->mBytesPerFrame;
            void *dataPointer = malloc((size_t)dataSize);
            memset(dataPointer, 0, dataSize);
            CMSampleTimingInfo timingInfo = {
                singleDuration,
                placeholderPresentationTimeStamp,
                kCMTimeInvalid
            };
            AudioBufferList audioBufferList;
            audioBufferList.mNumberBuffers = 1;
            audioBufferList.mBuffers[0].mNumberChannels = asbd->mChannelsPerFrame;
            audioBufferList.mBuffers[0].mDataByteSize = (UInt32)dataSize;
            audioBufferList.mBuffers[0].mData = dataPointer;
            CMSampleBufferRef placeholderSampleBuffer;
            CMSampleBufferCreate(kCFAllocatorDefault,
                                 NULL, false, NULL, NULL,
                                 _audioFormatDescription,
                                 (long)placeholderNumberOfSamples,
                                 1, &timingInfo, 0, NULL,
                                 &placeholderSampleBuffer);
            CMSampleBufferSetDataBufferFromAudioBufferList(placeholderSampleBuffer,
                                                           kCFAllocatorDefault,
                                                           kCFAllocatorDefault,
                                                           0,
                                                           &audioBufferList);
            if ([_assetWriterAudioInput appendSampleBuffer:placeholderSampleBuffer]) {
                _numberOfSamples += placeholderNumberOfSamples;
            }
            CFRelease(placeholderSampleBuffer);
            free(dataPointer);
        }
    }
    return placeholderNumberOfSamples;
}

#pragma mark - Video Process

- (void)processFristVideoFrame
{
    KTVVPFrame *frame = [self getFirstVideoFrame];
    if (!frame) {
        return;
    }
    if (_assetWriter.status != AVAssetWriterStatusWriting) {
        [frame unlock];
        return;
    }
    if (!_assetWriterVideoInput.readyForMoreMediaData) {
        [frame unlock];
        return;
    }
    [_videoTimeComponents putCurrentTimeStamp:frame.timeStamp];
    CMTime timeStamp = _videoTimeComponents.timeStamp;
    if (CMTimeCompare(timeStamp, _videoTimeComponents.previousTimeStamp) < 0) {
        KTVVPLog(@"KTVVPFrameWriter Frame time is less than previous time.");
        [frame unlock];
        return;
    }
    if (CMTIME_IS_INVALID(_assetWriterStartTime)) {
        KTVVPLog(@"Set start time by video track");
        [_assetWriter startSessionAtSourceTime:timeStamp];
        _assetWriterStartTime = timeStamp;
    }
    if (!_pixelBufferPool) {
        _pixelBufferPool = [[KTVVPPixelBufferPool alloc] init];
    }
    CVPixelBufferRef pixelBuffer = [_pixelBufferPool copyPixelBuffer:frame.corePixelBuffer];
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCVAttachmentMode_ShouldPropagate);
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
    if ([_assetWriterInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:timeStamp]) {
        if (_appendedFrameCallback) {
            _appendedFrameCallback(frame);
        }
        _numberOfFrames += 1;
    }
    CVPixelBufferRelease(pixelBuffer);
    [frame unlock];
}

- (void)insertVideoFrameInOrder:(KTVVPFrame *)frame
{
    [_frameQueue addObject:frame];
    [_frameQueue sortUsingComparator:^NSComparisonResult(KTVVPFrame *obj1, KTVVPFrame *obj2) {
        if (CMTimeCompare(obj1.timeStamp, obj2.timeStamp) > 0) {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
}

- (KTVVPFrame *)getFirstVideoFrame
{
    KTVVPFrame *frame = _frameQueue.firstObject;
    [_frameQueue removeObject:frame];
    return frame;
}

@end

