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
    [self cancelRecordingWithCompletionHandler:nil];
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
    _running = success;
    return success;
}

- (void)finishRecordingWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (!_running)
    {
        NSAssert(NO, @"");
        if (completionHandler)
        {
            completionHandler(NO);
        }
        return;
    }
    _running = NO;
    if (_assetWriter.status != AVAssetWriterStatusWriting)
    {
        NSAssert(NO, @"");
        if (completionHandler)
        {
            completionHandler(NO);
        }
        return;
    }
    dispatch_async(_runningQueue, ^{
        [_assetWriterVideoInput markAsFinished];
        [_assetWriter finishWritingWithCompletionHandler:^{
            if (completionHandler)
            {
                completionHandler(YES);
            }
        }];
    });
}

- (void)cancelRecordingWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (!_running)
    {
        if (completionHandler)
        {
            completionHandler(NO);
        }
        return;
    }
    _running = NO;
    if (_assetWriter.status != AVAssetWriterStatusWriting)
    {
        if (completionHandler)
        {
            completionHandler(NO);
        }
        return;
    }
    dispatch_async(_runningQueue, ^{
        [_assetWriterVideoInput markAsFinished];
        [_assetWriter cancelWriting];
        if (completionHandler)
        {
            completionHandler(YES);
        }
    });
}


#pragma mark - KTVVPInput

- (void)putFrame:(KTVVPFrame *)frame
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
        if (_assetWriter.status == AVAssetWriterStatusWriting
            && _assetWriterVideoInput.readyForMoreMediaData)
        {
            if (CMTIME_IS_INVALID(_videoStartTime))
            {
                [_assetWriter startSessionAtSourceTime:frame.time];
                _videoStartTime = frame.time;
            }
            CVPixelBufferRef pixelBuffer = frame.corePixelBuffer;
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:frame.time];
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            [frame unlock];
        }
    });
}

@end
