//
//  KTVVPFrameWriter.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/21.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameWriter.h"
#import "KTVVPTimeComponents.h"

@interface KTVVPFrameWriter ()

@property (nonatomic, strong) AVAssetWriter * assetWriter;
@property (nonatomic, strong) AVAssetWriterInput * assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor * assetWriterInputPixelBufferAdaptor;

@property (nonatomic, strong) NSMutableArray <KTVVPFrame *> * frameQueue;
@property (nonatomic, assign) NSTimeInterval asyncDelayIntervalInternal;
@property (nonatomic, strong) KTVVPTimeComponents * timeComponents;

@property (nonatomic, strong) dispatch_queue_t runningQueue;
@property (nonatomic, assign) BOOL running;

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
        _runningQueue = dispatch_queue_create("KTVVPFrameWriter-running-queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc
{
    if (_assetWriter.status == AVAssetWriterStatusWriting)
    {
        dispatch_sync(_runningQueue, ^{
            [_assetWriterVideoInput markAsFinished];
            [_assetWriter cancelWriting];
        });
    }
}


#pragma mark - Setup

- (void)setup
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
    _asyncDelayIntervalInternal = _asyncDelayInterval;
    _timeComponents = [[KTVVPTimeComponents alloc] init];
}

- (void)destory
{
    if (_assetWriter)
    {
        dispatch_sync(_runningQueue, ^{
            [_assetWriterVideoInput markAsFinished];
            [_assetWriter cancelWriting];
            [_frameQueue enumerateObjectsUsingBlock:^(KTVVPFrame * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [obj unlock];
            }];
            [_frameQueue removeAllObjects];
            _frameQueue = nil;
            _asyncDelayIntervalInternal = 0;
            _timeComponents = nil;
        });
    }
}


#pragma mark - Control

- (BOOL)startRecording
{
    if (_running)
    {
        return YES;
    }
    [self destory];
    [self setup];
    if (_error)
    {
        return NO;
    }
    if (![_assetWriter startWriting])
    {
        NSString * domain = @"Start writing failed";
        _error = [NSError errorWithDomain:domain code:-2 userInfo:nil];
        return NO;
    }
    _running = YES;
    return YES;
}

- (void)finishRecordingWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (completionHandler)
    {
        [self closeRecordingWithSuccess:^{
            [_assetWriterVideoInput markAsFinished];
            [_assetWriter finishWritingWithCompletionHandler:^{
                if (completionHandler)
                {
                    completionHandler(YES);
                }
            }];
        } failed:^{
            if (completionHandler)
            {
                completionHandler(NO);
            }
        }];
    }
}

- (void)cancelRecordingWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [self closeRecordingWithSuccess:^{
        [_assetWriterVideoInput markAsFinished];
        [_assetWriter cancelWriting];
        if (completionHandler)
        {
            completionHandler(YES);
        }
    } failed:^{
        if (completionHandler)
        {
            completionHandler(NO);
        }
    }];
}

- (void)closeRecordingWithSuccess:(void (^)(void))success failed:(void (^)(void))failed
{
    if (!_running)
    {
        if (failed)
        {
            failed();
        }
        return;
    }
    _running = NO;
    if (_assetWriter.status != AVAssetWriterStatusWriting)
    {
        if (failed)
        {
            failed();
        }
        return;
    }
    if (_asyncDelayIntervalInternal > 0)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_asyncDelayIntervalInternal * NSEC_PER_SEC)), _runningQueue, ^{
            if (success)
            {
                success();
            }
        });
    }
    else
    {
        dispatch_async(_runningQueue, ^{
            if (success)
            {
                success();
            }
        });
    }
}


#pragma mark - KTVVPFrameInput

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (!_running)
    {
        return;
    }
    if (_assetWriter.status != AVAssetWriterStatusWriting)
    {
        return;
    }
    CMTime timeStamp = frame.timeStamp;
    if (CMTIME_IS_INVALID(timeStamp))
    {
        NSAssert(NO, @"timeStamp must a vaild CMTime value");
        return;
    }
    if (_paused)
    {
        dispatch_async(_runningQueue, ^{
            if (_asyncDelayIntervalInternal > 0)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_asyncDelayIntervalInternal * NSEC_PER_SEC)), _runningQueue, ^{
                    [_timeComponents putDroppedTimeStamp:timeStamp];
                });
            }
            else
            {
                [_timeComponents putDroppedTimeStamp:timeStamp];
            }
        });
    }
    else
    {
        [frame lock];
        dispatch_async(_runningQueue, ^{
            [self insertFrameInOrder:frame];
            if (_asyncDelayIntervalInternal > 0)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_asyncDelayIntervalInternal * NSEC_PER_SEC)), _runningQueue, ^{
                    [_timeComponents putCurrentTimeStamp:timeStamp];
                    [self processFristFrame];
                });
            }
            else
            {
                [_timeComponents putCurrentTimeStamp:timeStamp];
                [self processFristFrame];
            }
        });
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
    if (_assetWriter.status != AVAssetWriterStatusWriting
        || !_assetWriterVideoInput.readyForMoreMediaData)
    {
        [frame unlock];
        return;
    }
    if (CMTIME_IS_VALID(_timeComponents.timeStamp)
        && CMTIME_IS_VALID(_videoPreviousFrameTime))
    {
        if (CMTimeCompare(_timeComponents.timeStamp, _videoPreviousFrameTime) < 0)
        {
            NSLog(@"KTVVPFrameWriter Frame time is less than previous time.");
            [frame unlock];
            return;
        }
    }
    if (CMTIME_IS_INVALID(_videoStartTime))
    {
        [_assetWriter startSessionAtSourceTime:_timeComponents.timeStamp];
        _videoStartTime = _timeComponents.timeStamp;
    }
    _videoPreviousFrameTime = _timeComponents.timeStamp;
    CVPixelBufferRef pixelBuffer = frame.corePixelBuffer;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:_timeComponents.timeStamp];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [frame unlock];
}

- (void)insertFrameInOrder:(KTVVPFrame *)frame
{
    [_frameQueue addObject:frame];
    [_frameQueue sortUsingComparator:^NSComparisonResult(KTVVPFrame * obj1, KTVVPFrame * obj2) {
        if (CMTIME_IS_VALID(obj1.timeStamp)
            && CMTIME_IS_VALID(obj2.timeStamp))
        {
            if (CMTimeCompare(obj1.timeStamp, obj2.timeStamp) > 0)
            {
                return NSOrderedDescending;
            }
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
