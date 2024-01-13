//
//  KTVVPCaptureSession.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPCaptureSession.h"
#import "KTVVPFramePool.h"
#import "KTVVPCMSmapleBufferFrame.h"
#import "KTVVPTimeComponents.h"
#import "KTVVPLog.h"

@interface KTVVPCaptureSession () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, copy) AVCaptureSessionPreset sessionPresetInternal;
@property (nonatomic, assign) UIInterfaceOrientation orientationInternal;
@property (nonatomic, assign) AVCaptureDevicePosition positionInternal;
@property (nonatomic, assign) BOOL horizontalFlipForFrontInternal;

@property (nonatomic, strong) AVCaptureDevice * audioDevice;
@property (nonatomic, strong) AVCaptureDevice * videoDevice;

@property (nonatomic, strong) AVCaptureDeviceInput * audioInput;
@property (nonatomic, strong) AVCaptureDeviceInput * videoInput;

@property (nonatomic, strong) AVCaptureAudioDataOutput * audioDataOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * videoDataOutput;

@property (nonatomic, strong) dispatch_queue_t audioProcessingQueue;
@property (nonatomic, strong) dispatch_queue_t videoProcessingQueue;

@property (nonatomic, strong) KTVVPTimeComponents * audioTimeComponents;
@property (nonatomic, strong) KTVVPTimeComponents * videoTimeComponents;

@property (nonatomic, strong) KTVVPFramePool * framePool;
@property (nonatomic, assign) NSInteger configurationCount;
@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didCallStart;

@end

@implementation KTVVPCaptureSession

- (instancetype)init
{
    if (self = [super init])
    {
        _captureSession = [[AVCaptureSession alloc] init];
        _audioTimeComponents = [[KTVVPTimeComponents alloc] init];
        _videoTimeComponents = [[KTVVPTimeComponents alloc] init];
        _sessionPreset = AVCaptureSessionPreset1280x720;
        _position = AVCaptureDevicePositionFront;
        _orientation = UIInterfaceOrientationPortrait;
        _horizontalFlipForFront = YES;
        [self reloadInternal];
    }
    return self;
}

- (void)dealloc
{
    KTVVPLog(@"%s", __func__);
}

- (void)prepare
{
    if (_didCallPrepare)
    {
        return;
    }
    _didCallPrepare = YES;
    [self reloadVideoOutput];
    [self reloadAudioOutput];
    [self reloadSessionPreset];
    [self reloadPosition];
}

- (void)start
{
    if (_didCallStart)
    {
        return;
    }
    _didCallStart = YES;
    [self prepare];
    [_captureSession startRunning];
}

- (void)stop
{
    [_captureSession stopRunning];
}

- (void)beginConfiguration
{
    _configurationCount++;
    [_captureSession beginConfiguration];
}

- (void)commitConfiguration
{
    [_captureSession commitConfiguration];
    _configurationCount--;
    if (_configurationCount <= 0)
    {
        _configurationCount = 0;
        [self reloadInternal];
    }
}

#pragma mark - Setup

- (void)reloadVideoOutput
{
    [self beginConfiguration];
    if (_videoDataOutput)
    {
        [_captureSession removeOutput:_videoDataOutput];
        _videoDataOutput = nil;
    }
    if (!_videoProcessingQueue)
    {
        _videoProcessingQueue = dispatch_queue_create("KTVVPCaptureSession-Video", DISPATCH_QUEUE_SERIAL);
    }
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    if ([_captureSession canAddOutput:_videoDataOutput])
    {
        [_captureSession addOutput:_videoDataOutput];
    }
    [self commitConfiguration];
}

- (void)reloadAudioOutput
{
    [self beginConfiguration];
    if (_audioEnable)
    {
        if (!_audioDevice)
        {
            _audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        }
        if (!_audioInput)
        {
            _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:_audioDevice error:nil];
            if ([_captureSession canAddInput:_audioInput])
            {
                [_captureSession addInput:_audioInput];
            }
        }
        if (!_audioDataOutput)
        {
            if (!_audioProcessingQueue)
            {
                _audioProcessingQueue = dispatch_queue_create("KTVVPCaptureSession-Audio", DISPATCH_QUEUE_SERIAL);
            }
            _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
            [_audioDataOutput setSampleBufferDelegate:self queue:_audioProcessingQueue];
            if ([_captureSession canAddOutput:_audioDataOutput])
            {
                [_captureSession addOutput:_audioDataOutput];
            }
        }
    }
    else
    {
        if (_audioInput)
        {
            [_captureSession removeInput:_audioInput];
            _audioInput = nil;
        }
        if (_audioDataOutput)
        {
            [_captureSession removeOutput:_audioDataOutput];
            _audioDataOutput = nil;
        }
        _audioDevice = nil;
    }
    [self commitConfiguration];
}

- (void)reloadSessionPreset
{
    [self beginConfiguration];
    _captureSession.sessionPreset = _sessionPreset;
    [self commitConfiguration];
}

- (void)reloadPosition
{
    [self beginConfiguration];
    if (_videoInput)
    {
        [_captureSession removeInput:_videoInput];
        _videoInput = nil;
    }
    _videoDevice = nil;
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice * device in devices)
    {
        if (device.position == _position)
        {
            _videoDevice = device;
        }
    }
    if (_videoDevice)
    {
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:nil];
        if ([_captureSession canAddInput:_videoInput])
        {
            [_captureSession addInput:_videoInput];
        }
    }
    else
    {
        _error = [NSError errorWithDomain:@"No vaild camera device." code:-1 userInfo:nil];
    }
    [self commitConfiguration];
}

- (void)reloadOrientation
{
    [self beginConfiguration];
    [self commitConfiguration];
}

- (void)reloadHorizontalFlipForFront
{
    [self beginConfiguration];
    [self commitConfiguration];
}

- (void)reloadInternal
{
    _sessionPresetInternal = _sessionPreset;
    _positionInternal = _position;
    _orientationInternal = _orientation;
    _horizontalFlipForFrontInternal = _horizontalFlipForFront;
}


#pragma mark - Setter/Getter

- (void)setPosition:(AVCaptureDevicePosition)position
{
    if (_position != position)
    {
        _position = position;
        [self reloadPosition];
    }
}

- (void)setSessionPreset:(AVCaptureSessionPreset)sessionPreset
{
    if (![_sessionPreset isEqualToString:sessionPreset])
    {
        _sessionPreset = sessionPreset;
        [self reloadSessionPreset];
    }
}

- (void)setOrientation:(UIInterfaceOrientation)orientation
{
    if (_orientation != orientation)
    {
        _orientation = orientation;
        [self reloadOrientation];
    }
}

- (void)setHorizontalFlipForFront:(BOOL)horizontalFlipForFront
{
    if (_horizontalFlipForFront != horizontalFlipForFront)
    {
        _horizontalFlipForFront = horizontalFlipForFront;
        [self reloadHorizontalFlipForFront];
    }
}

- (void)setAudioEnable:(BOOL)audioEnable
{
    if (_didCallStart)
    {
        return;
    }
    if (_audioEnable != audioEnable)
    {
        _audioEnable = audioEnable;
        [self reloadAudioOutput];
    }
}

- (KTVVPRotationMode)rotationMode
{
    switch (_orientationInternal)
    {
        case UIInterfaceOrientationUnknown:
        case UIInterfaceOrientationPortrait:
            return KTVVPRotationMode270;
        case UIInterfaceOrientationLandscapeLeft:
            if (_positionInternal == AVCaptureDevicePositionBack)
            {
                return KTVVPRotationMode180;
            }
            return KTVVPRotationMode0;
        case UIInterfaceOrientationLandscapeRight:
            if (_positionInternal == AVCaptureDevicePositionBack)
            {
                return KTVVPRotationMode0;
            }
            return KTVVPRotationMode180;
        case UIInterfaceOrientationPortraitUpsideDown:
            return KTVVPRotationMode90;
    }
    return KTVVPRotationMode270;
}

- (KTVVPFlipMode)flipMode
{
    if (_positionInternal == AVCaptureDevicePositionFront
        && _horizontalFlipForFrontInternal)
    {
        return KTVVPFlipModeHorizonal;
    }
    return KTVVPFlipModeNone;
}

- (CGPoint)convertPointToCurrentTranform:(CGPoint)point
{
    CGPoint flipPoint = point;
    switch ([self flipMode])
    {
        case KTVVPFlipModeNone:
            break;
        case KTVVPFlipModeVertical:
            flipPoint = CGPointMake(point.x, 1 - point.y);
            break;
        case KTVVPFlipModeHorizonal:
            flipPoint = CGPointMake(1 - point.x, point.y);
            break;
        case KTVVPFlipModeHorizonalAndVertical:
            flipPoint = CGPointMake(1 - point.x, 1 - point.y);
            break;
    }
    CGPoint ret = flipPoint;
    switch ([self rotationMode])
    {
        case KTVVPRotationMode0:
            break;
        case KTVVPRotationMode90:
            ret = CGPointMake(1.0 - flipPoint.y, flipPoint.x);
            break;
        case KTVVPRotationMode180:
            ret = CGPointMake(1.0 - flipPoint.y, 1.0 - flipPoint.x);
            break;
        case KTVVPRotationMode270:
            ret = CGPointMake(flipPoint.y, 1.0 - flipPoint.x);
            break;
    }
    return  ret;
}


#pragma mark - Configuration

- (void)setMinFrameDuration:(CMTime)minFrameDuration
{
    [self beginConfiguration];
    if ([_videoDevice lockForConfiguration:nil])
    {
        [_videoDevice setActiveVideoMinFrameDuration:minFrameDuration];
        [_videoDevice unlockForConfiguration];
    }
    [self commitConfiguration];
}

- (CMTime)minFrameDuration
{
    return _videoDevice.activeVideoMinFrameDuration;
}

- (void)setMaxFrameDuration:(CMTime)maxFrameDuration
{
    [self beginConfiguration];
    if ([_videoDevice lockForConfiguration:nil])
    {
        [_videoDevice setActiveVideoMaxFrameDuration:maxFrameDuration];
        [_videoDevice unlockForConfiguration];
    }
    [self commitConfiguration];
}

- (CMTime)maxFrameDuration
{
    return _videoDevice.activeVideoMaxFrameDuration;
}

- (BOOL)torchSupported
{
    return _videoDevice.torchAvailable;
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode
{
    [self beginConfiguration];
    if ([_videoDevice lockForConfiguration:nil])
    {
        _videoDevice.torchMode = torchMode;
        [_videoDevice unlockForConfiguration];
    }
    [self commitConfiguration];
}

- (AVCaptureTorchMode)torchMode
{
    return _videoDevice.torchMode;
}

- (BOOL)isFocusModeSupported:(AVCaptureFocusMode)focusMode
{
    return [_videoDevice isFocusModeSupported:focusMode];
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode
{
    [self beginConfiguration];
    if ([_videoDevice lockForConfiguration:nil])
    {
        _videoDevice.focusMode = focusMode;
        [_videoDevice unlockForConfiguration];
    }
    [self commitConfiguration];
}

- (AVCaptureFocusMode)focusMode
{
    return _videoDevice.focusMode;
}

- (BOOL)focusPointOfInterestSupported
{
    return _videoDevice.focusPointOfInterestSupported;
}

- (void)setFocusPointOfInterest:(CGPoint)focusPointOfInterest
{
    [self beginConfiguration];
    if ([_videoDevice lockForConfiguration:nil])
    {
        _videoDevice.focusPointOfInterest = [self convertPointToCurrentTranform:focusPointOfInterest];
        _videoDevice.focusMode = [self focusMode];
        [_videoDevice unlockForConfiguration];
    }
    [self commitConfiguration];
}

- (CGPoint)focusPointOfInterest
{
    return _videoDevice.focusPointOfInterest;
}

- (BOOL)isExposureModeSupported:(AVCaptureExposureMode)exposureMode
{
    return [_videoDevice isExposureModeSupported:exposureMode];
}

- (void)setExposureMode:(AVCaptureExposureMode)exposureMode
{
    [self beginConfiguration];
    if ([_videoDevice lockForConfiguration:nil])
    {
        _videoDevice.exposureMode = exposureMode;
        [_videoDevice unlockForConfiguration];
    }
    [self commitConfiguration];
}

- (AVCaptureExposureMode)exposureMode
{
    return _videoDevice.exposureMode;
}

- (BOOL)exposurePointOfInterestSupported
{
    return _videoDevice.exposurePointOfInterestSupported;
}

- (void)setExposurePointOfInterest:(CGPoint)exposurePointOfInterest
{
    [self beginConfiguration];
    if ([_videoDevice lockForConfiguration:nil])
    {
        _videoDevice.exposurePointOfInterest = [self convertPointToCurrentTranform:exposurePointOfInterest];
        _videoDevice.exposureMode = [self exposureMode];
        [_videoDevice unlockForConfiguration];
    }
    [self commitConfiguration];
}

- (CGPoint)exposurePointOfInterest
{
    return _videoDevice.exposurePointOfInterest;
}

- (BOOL)videoStabilizationSupported
{
    AVCaptureConnection * connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    return connection.supportsVideoStabilization;
}

- (AVCaptureVideoStabilizationMode)activeVideoStabilizationMode
{
    AVCaptureConnection * connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    return connection.activeVideoStabilizationMode;
}

- (void)setPreferredVideoStabilizationMode:(AVCaptureVideoStabilizationMode)preferredVideoStabilizationMode
{
    AVCaptureConnection * connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.preferredVideoStabilizationMode = preferredVideoStabilizationMode;
}

- (AVCaptureVideoStabilizationMode)preferredVideoStabilizationMode
{
    AVCaptureConnection * connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    return connection.preferredVideoStabilizationMode;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (output == _videoDataOutput)
    {
        if (self.paused)
        {
            [_videoTimeComponents putDroppedTimeStamp:presentationTimeStamp];
        }
        else
        {
            [_videoTimeComponents putCurrentTimeStamp:presentationTimeStamp];
            if (self.pipeline)
            {
                if (!_framePool)
                {
                    _framePool = [[KTVVPFramePool alloc] init];
                }
                KTVVPCMSmapleBufferFrame * frame = [_framePool frameWithKey:[KTVVPCMSmapleBufferFrame key] factory:^__kindof KTVVPFrame *{
                    KTVVPCMSmapleBufferFrame * result = [[KTVVPCMSmapleBufferFrame alloc] init];
                    return result;
                }];
                frame.sampleBuffer = sampleBuffer;
                frame.timeStamp = _videoTimeComponents.timeStamp;
                frame.hostTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                frame.layout.rotationMode = [self rotationMode];
                frame.layout.flipMode = [self flipMode];
                [self.pipeline inputFrame:frame fromSource:self];
                [frame unlock];
            }
        }
    }
    else if (output == _audioDataOutput)
    {
        if (self.paused)
        {
            [_audioTimeComponents putDroppedTimeStamp:presentationTimeStamp];
        }
        else
        {
            [_audioTimeComponents putCurrentTimeStamp:presentationTimeStamp];
            if (_audioOutput)
            {
                KTVVPSample * sample = [[KTVVPSample alloc] init];
                sample.sampleBuffer = sampleBuffer;
                sample.timeStamp = _audioTimeComponents.timeStamp;
                sample.hostTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                [_audioOutput inputSample:sample fromSource:self];
            }
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (output == _videoDataOutput)
    {
        KTVVPLog(@"Video : %s", __func__);
    }
    else if (output == _audioDataOutput)
    {
        KTVVPLog(@"Audio : %s", __func__);
    }
}

@end
