//
//  KTVVPExportSession.m
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/4.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPExportSession.h"
#import "KTVVPExportReader.h"
#import "KTVVPExportWriter.h"

@interface KTVVPExportSession () <KTVVPFrameInput>

@property (nonatomic, strong) KTVVPExportReader * reader;
@property (nonatomic, strong) KTVVPExportWriter * writer;
@property (nonatomic, strong) KTVVPFrame * tempFrame;
@property (nonatomic, assign) BOOL didCalceled;

@end

@implementation KTVVPExportSession

- (instancetype)init
{
    if (self = [super init])
    {
        NSLog(@"%s", __func__);
        _preferredFlag = KTVVPAVFlagAudioVideo;
        _writerFileType = AVFileTypeMPEG4;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
}

- (void)start
{
    __weak typeof(self) weakSelf = self;
    [_pipeline addOutput:self];
    _reader = [[KTVVPExportReader alloc] initWithURL:_sourceURL preferredFlag:_preferredFlag];
    _reader.audioOutputSettings = _readerAudioOutputSettings;
    _reader.videoOutputSettings = _readerVideoOutputSettings;
    [_reader start];
    if (_reader.error)
    {
        _error = _reader.error;
        [self callbackForFailed];
        return;
    }
    _writer = [[KTVVPExportWriter alloc] initWithURL:_destinationURL size:_reader.size  flag:_reader.actualFlag];
    _writer.fileType = _writerFileType;
    _writer.audioOutputSettings = _writerAudioOutputSettings;
    _writer.videoOutputSettings = _writerVideoOutputSettings;
    [_writer start];
    if (_writer.error)
    {
        _error = _writer.error;
        [self callbackForFailed];
        return;
    }
    [_writer appendWhenReadyWithFrameCallback:^{
        [weakSelf appendNextFrame];
    } sampleCallback:^{
        [weakSelf appendNextSample];
    } finishCallback:^{
        NSLog(@"KTVVPExportSession Finished");
        [weakSelf callbackForFinished];
    }];
}

- (void)cancel
{
    _didCalceled = YES;
    [_writer cancel];
    [self destory];
}

- (void)appendNextFrame
{
    while (!_didCalceled && [_writer readyForMoreFrame])
    {
        KTVVPFrame * frame = [_reader nextFrame];
        if (frame)
        {
            BOOL ret = [_pipeline inputFrame:frame fromSource:self];
            if (ret)
            {
                [_pipeline waitUntilFinished];
                if (_tempFrame)
                {
                    if (_progressCallback)
                    {
                        [self callbackForProgress:_tempFrame.timeStamp];
                    }
                    [_writer appendFrame:_tempFrame];
                    [_tempFrame unlock];
                    _tempFrame = nil;
                }
            }
            [frame unlock];
        }
        else
        {
            [_writer markFrameAsFinished];
        }
    }
}

- (void)appendNextSample
{
    while (!_didCalceled && [_writer readyForMoreSample])
    {
        KTVVPSample * sample = [_reader nextSample];
        if (sample)
        {
            if (_progressCallback
                && !(_reader.actualFlag & KTVVPAVFlagVideo))
            {
                [self callbackForProgress:sample.timeStamp];
            }
            [_writer appendSample:sample];
        }
        else
        {
            [_writer markSampleAsFinished];
        }
    }
}

- (void)callbackForProgress:(CMTime)time
{
    if (_progressCallback)
    {
        float progress = CMTimeGetSeconds(time) / CMTimeGetSeconds(_reader.duration);
        progress = MIN(progress, 1.0);
        progress = MAX(progress, 0.0);
        _progressCallback(progress);
    }
}

- (void)callbackForFinished
{
    if (_progressCallback)
    {
        _progressCallback(1.0);
    }
    if (_completionCallback)
    {
        _completionCallback(_destinationURL, nil);
    }
    [self destory];
}

- (void)callbackForFailed
{
    if (_completionCallback)
    {
        _completionCallback(nil, _error);
    }
    [self destory];
}

- (void)destory
{
    _progressCallback = nil;
    _completionCallback = nil;
    [_pipeline removeOutput:self];
}

#pragma mark - KTVVPFrameInput

- (BOOL)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    _tempFrame = frame;
    [_tempFrame lock];
    return YES;
}

@end
