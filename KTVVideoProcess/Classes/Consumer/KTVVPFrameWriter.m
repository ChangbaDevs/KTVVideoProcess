//
//  KTVVPFrameWriter.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/21.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameWriter.h"

@interface KTVVPFrameWriter ()

@property (nonatomic, strong) AVAssetWriter * assetWriter;
@property (nonatomic, strong) AVAssetWriterInput * assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor * assetWriterInputPixelBufferAdaptor;

@property (nonatomic, strong) NSMutableArray <KTVVPFrame *> * frameQueue;
@property (nonatomic, assign) NSTimeInterval asyncDelayIntervalInternal;

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


#pragma mark - Control

- (BOOL)startRecording
{
    if (!_outputFileURL || !_outputFileType)
    {
        NSString * domain = @"outputFileURL and outputFileType can't be nil";
        NSAssert(NO, domain);
        _error = [NSError errorWithDomain:domain code:-1 userInfo:nil];
        return NO;
    }
    
    NSError * error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:_outputFileURL fileType:_outputFileType error:&error];
    if (error)
    {
        _error = error;
        return NO;
    }
    
    _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:_videoOutputSettings];
    _assetWriterVideoInput.expectsMediaDataInRealTime = NO;
    _assetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:_videoSourcePixelBufferAttributes];
    [_assetWriter addInput:_assetWriterVideoInput];
    BOOL success = [_assetWriter startWriting];
    if (!success)
    {
        return NO;
    }
    
    _frameQueue = [NSMutableArray array];
    _asyncDelayIntervalInternal = _asyncDelayInterval;
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
    if (_paused)
    {
        return;
    }
    if (_assetWriter.status != AVAssetWriterStatusWriting)
    {
        return;
    }
    [frame lock];
    dispatch_async(_runningQueue, ^{
        [self insertFrameInOrder:frame];
        if (_asyncDelayIntervalInternal > 0)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_asyncDelayIntervalInternal * NSEC_PER_SEC)), _runningQueue, ^{
                [self processFristFrame];
            });
        }
        else
        {
            [self processFristFrame];
        }
    });
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
    if (CMTIME_IS_VALID(frame.time)
        && CMTIME_IS_VALID(_videoPreviousFrameTime))
    {
        if (CMTimeCompare(frame.time, _videoPreviousFrameTime) < 0)
        {
            NSLog(@"KTVVPFrameWriter Frame time is less than previous time.");
            [frame unlock];
            return;
        }
    }
    if (CMTIME_IS_INVALID(_videoStartTime))
    {
        [_assetWriter startSessionAtSourceTime:frame.time];
        _videoStartTime = frame.time;
    }
    _videoPreviousFrameTime = frame.time;
    CVPixelBufferRef pixelBuffer = frame.corePixelBuffer;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:frame.time];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    [frame unlock];
}

- (void)insertFrameInOrder:(KTVVPFrame *)frame
{
    [_frameQueue addObject:frame];
    [_frameQueue sortUsingComparator:^NSComparisonResult(KTVVPFrame * obj1, KTVVPFrame * obj2) {
        if (CMTIME_IS_VALID(obj1.time)
            && CMTIME_IS_VALID(obj2.time))
        {
            if (CMTimeCompare(obj1.time, obj2.time) > 0)
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
