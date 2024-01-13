//
//  KTVVPExportReader.m
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/4.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPExportReader.h"
#import "KTVVPFramePool.h"
#import "KTVVPCMSmapleBufferFrame.h"

@interface KTVVPExportReader ()

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVAssetReader *reader;
@property (nonatomic, strong) AVAssetTrack *audioTrack;
@property (nonatomic, strong) AVAssetTrack *videoTrack;
@property (nonatomic, strong) AVAssetReaderOutput *audioOutput;
@property (nonatomic, strong) AVAssetReaderOutput *videoOutput;
@property (nonatomic, strong) KTVVPFramePool *framePool;

@end

@implementation KTVVPExportReader

- (instancetype)initWithURL:(NSURL *)URL
              preferredFlag:(KTVVPAVFlag)preferredFlag
{
    if (self = [super init]) {
        _URL = URL;
        _preferredFlag = preferredFlag;
        _actualFlag = KTVVPAVFlagNone;
        _size = KTVVPSizeMake(0, 0);
        _duration = kCMTimeZero;
        _audioTimeRange = kCMTimeRangeZero;
        _videoTimeRange = kCMTimeRangeZero;
    }
    return self;
}

- (KTVVPFrame *)nextFrame
{
    if (_videoOutput) {
        CMSampleBufferRef sampleBuffer = [_videoOutput copyNextSampleBuffer];
        if (sampleBuffer) {
            if (!_framePool) {
                _framePool = [[KTVVPFramePool alloc] init];
            }
            KTVVPCMSmapleBufferFrame *frame = [_framePool frameWithKey:[KTVVPCMSmapleBufferFrame key] factory:^__kindof KTVVPFrame *{
                KTVVPCMSmapleBufferFrame *result = [[KTVVPCMSmapleBufferFrame alloc] init];
                return result;
            }];
            frame.sampleBuffer = sampleBuffer;
            frame.timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            frame.hostTimeStamp = CMTimeMakeWithSeconds(CACurrentMediaTime(), INT32_MAX);
            CFRelease(sampleBuffer);
            return frame;
        }
    }
    return nil;
}

- (KTVVPSample *)nextSample
{
    if (_audioOutput) {
        CMSampleBufferRef sampleBuffer = [_audioOutput copyNextSampleBuffer];
        if (sampleBuffer) {
            KTVVPSample *sample = [[KTVVPSample alloc] init];
            sample.sampleBuffer = sampleBuffer;
            CFRelease(sampleBuffer);
            return sample;
        }
    }
    return nil;
}

- (void)start
{
    _asset = [AVAsset assetWithURL:_URL];
    _reader = [AVAssetReader assetReaderWithAsset:_asset error:nil];
    if (_preferredFlag & KTVVPAVFlagAudio) {
        _audioTrack = [_asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        if (_audioTrack) {
            if (!_audioOutputSettings) {
                NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
                [outputSettings setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
                [outputSettings setObject:@(44100) forKey:AVSampleRateKey];
                [outputSettings setObject:@(2) forKey:AVNumberOfChannelsKey];
                [outputSettings setObject:@(32) forKey:AVLinearPCMBitDepthKey];
                [outputSettings setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
                _audioOutputSettings = outputSettings;
            }
            _audioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:_audioTrack outputSettings:_audioOutputSettings];
            _audioOutput.alwaysCopiesSampleData = NO;
            [_reader addOutput:_audioOutput];
            _actualFlag |= KTVVPAVFlagAudio;
            _audioTimeRange = _audioTrack.timeRange;
        }
    }
    if (_preferredFlag & KTVVPAVFlagVideo) {
        _videoTrack = [_asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (_videoTrack) {
            if (!_videoOutputSettings) {
                NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
                [outputSettings setObject:@(kCVPixelFormatType_32BGRA) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
                _videoOutputSettings = outputSettings;
            }
            _videoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:_videoTrack outputSettings:_videoOutputSettings];
            _videoOutput.alwaysCopiesSampleData = NO;
            [_reader addOutput:_videoOutput];
            _size = KTVVPSizeMake(_videoTrack.naturalSize.width, _videoTrack.naturalSize.height);
            _actualFlag |= KTVVPAVFlagVideo;
            _videoTimeRange = _videoTrack.timeRange;
        }
    }
    _duration = _asset.duration;
    [_reader startReading];
}

- (NSError *)error
{
    return _reader.error;
}

@end
