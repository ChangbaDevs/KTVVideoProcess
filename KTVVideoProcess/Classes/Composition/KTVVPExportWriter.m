//
//  KTVVPExportWriter.m
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/4.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPExportWriter.h"
#import "KTVVPPixelBufferPool.h"

@interface KTVVPExportWriter ()

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, assign) KTVVPSize size;
@property (nonatomic, assign) KTVVPAVFlag flag;

@property (nonatomic, assign) KTVVPAVFlag appendFlag;
@property (nonatomic, assign) CMTime startTime;
@property (nonatomic, strong) AVAssetWriter * writer;
@property (nonatomic, strong) AVAssetWriterInput * audioInput;
@property (nonatomic, strong) AVAssetWriterInput * videoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor * videoInputAdaptor;
@property (nonatomic, strong) dispatch_queue_t audioRunningQueue;
@property (nonatomic, strong) dispatch_queue_t videoRunningQueue;
@property (nonatomic, strong) KTVVPPixelBufferPool * pixelBufferPool;
@property (nonatomic, copy) void (^finishCallback)(void);

@end

@implementation KTVVPExportWriter

- (instancetype)initWithURL:(NSURL *)URL size:(KTVVPSize)size flag:(KTVVPAVFlag)flag
{
    if (self = [super init])
    {
        _URL = URL;
        _size = size;
        _flag = flag;
        _fileType = AVFileTypeMPEG4;
        _appendFlag = KTVVPAVFlagNone;
        _startTime = kCMTimeInvalid;
    }
    return self;
}

- (void)appendWhenReadyWithFrameCallback:(void (^)(void))frameCallback sampleCallback:(void (^)(void))sampleCallback finishCallback:(void (^)(void))finishCallback
{
    if (_videoInput && frameCallback)
    {
        [_videoInput requestMediaDataWhenReadyOnQueue:_videoRunningQueue usingBlock:frameCallback];
    }
    if (_audioInput && sampleCallback)
    {
        [_audioInput requestMediaDataWhenReadyOnQueue:_audioRunningQueue usingBlock:sampleCallback];
    }
    _finishCallback = finishCallback;
}

- (BOOL)readyForMoreFrame
{
    return _videoInput.readyForMoreMediaData && (_appendFlag & KTVVPAVFlagVideo);
}

- (BOOL)readyForMoreSample
{
    return _audioInput.readyForMoreMediaData && (_appendFlag & KTVVPAVFlagAudio);
}

- (void)appendFrame:(KTVVPFrame *)frame
{
    if (!frame || !frame.corePixelBuffer || ![self readyForMoreFrame])
    {
        return;
    }
    [self setStartTimeIfNeeded:frame.timeStamp];
    CVPixelBufferRef pixelBuffer = [_pixelBufferPool copyPixelBuffer:frame.corePixelBuffer];
    [_videoInputAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:frame.timeStamp];
    CVPixelBufferRelease(pixelBuffer);
}

- (void)appendSample:(KTVVPSample *)sample
{
    if (!sample || ![self readyForMoreSample])
    {
        return;
    }
    [self setStartTimeIfNeeded:sample.timeStamp];
    [_audioInput appendSampleBuffer:sample.sampleBuffer];
}

- (void)setStartTimeIfNeeded:(CMTime)time
{
    if (CMTIME_IS_INVALID(_startTime))
    {
        _startTime = time;
        [_writer startSessionAtSourceTime:_startTime];
    }
}

- (void)markFrameAsFinished
{
    if (_appendFlag & KTVVPAVFlagVideo)
    {
        _appendFlag &= ~KTVVPAVFlagVideo;
        [_videoInput markAsFinished];
        [self finishIfNeeded];
    }
}

- (void)markSampleAsFinished
{
    if (_appendFlag & KTVVPAVFlagAudio)
    {
        _appendFlag &= ~KTVVPAVFlagAudio;
        [_audioInput markAsFinished];
        [self finishIfNeeded];
    }
}

- (void)finishIfNeeded
{
    if (!(_appendFlag & KTVVPAVFlagAudio) && !(_appendFlag & KTVVPAVFlagVideo))
    {
        [_writer finishWritingWithCompletionHandler:^{
            if (_finishCallback)
            {
                _finishCallback();
                _finishCallback = nil;
            }
        }];
    }
}

- (void)start
{
    _pixelBufferPool = [[KTVVPPixelBufferPool alloc] init];
    if ([[NSFileManager defaultManager] fileExistsAtPath:_URL.path])
    {
        [[NSFileManager defaultManager] removeItemAtURL:_URL error:nil];
    }
    _writer = [AVAssetWriter assetWriterWithURL:_URL fileType:_fileType error:nil];
    if (_flag & KTVVPAVFlagAudio)
    {
        _audioRunningQueue = dispatch_queue_create("KTVSVAVFrameWriter-AudioRunningQueue", DISPATCH_QUEUE_SERIAL);
        if (!_audioOutputSettings)
        {
            NSMutableDictionary * outputSettings = [[NSMutableDictionary alloc] init];
            [outputSettings setObject:@(kAudioFormatMPEG4AAC) forKey:AVFormatIDKey];
            [outputSettings setObject:@(44100) forKey:AVSampleRateKey];
            [outputSettings setObject:@(2) forKey:AVNumberOfChannelsKey];
            AudioChannelLayout acl;
            bzero(&acl, sizeof(acl));
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
            NSData * aclData = [NSData dataWithBytes:&acl length:sizeof(acl)];
            [outputSettings setObject:aclData forKey:AVChannelLayoutKey];
            _audioOutputSettings = outputSettings;
        }
        _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:_audioOutputSettings];
        [_writer addInput:_audioInput];
        _appendFlag |= KTVVPAVFlagAudio;
    }
    if (_flag & KTVVPAVFlagVideo)
    {
        _videoRunningQueue = dispatch_queue_create("KTVSVAVFrameWriter-VideoRunningQueue", DISPATCH_QUEUE_SERIAL);
        if (!_videoOutputSettings)
        {
            NSMutableDictionary * outputSettings = [[NSMutableDictionary alloc] init];
            if (@available(iOS 11.0, *)) {
                [outputSettings setObject:AVVideoCodecTypeH264 forKey:AVVideoCodecKey];
            } else {
                [outputSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
            }
            [outputSettings setObject:@(_size.width) forKey:AVVideoWidthKey];
            [outputSettings setObject:@(_size.height) forKey:AVVideoHeightKey];
            _videoOutputSettings = outputSettings;
        }
        _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:_videoOutputSettings];
        NSMutableDictionary * adaptorSettings = [[NSMutableDictionary alloc] init];
        [adaptorSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [adaptorSettings setObject:[_videoOutputSettings objectForKey:AVVideoWidthKey] forKey:(id)kCVPixelBufferWidthKey];
        [adaptorSettings setObject:[_videoOutputSettings objectForKey:AVVideoHeightKey] forKey:(id)kCVPixelBufferHeightKey];
        _videoInputAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoInput sourcePixelBufferAttributes:adaptorSettings];
        [_writer addInput:_videoInput];
        _appendFlag |= KTVVPAVFlagVideo;
    }
    [_writer startWriting];
}

- (void)cancel
{
    _appendFlag = KTVVPAVFlagNone;
    [_audioInput markAsFinished];
    [_videoInput markAsFinished];
    [_writer cancelWriting];
}

- (NSError *)error
{
    return _writer.error;
}

@end
