//
//  KTVVPVideoCamera.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPVideoCamera.h"
#import "KTVVPFramePool.h"
#import "KTVVPFrameCMSmapleBuffer.h"
#import "KTVVPTimeComponents.h"

@interface KTVVPVideoCamera () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, copy) AVCaptureSessionPreset sessionPresetInternal;
@property (nonatomic, assign) AVCaptureDevicePosition positionInternal;
@property (nonatomic, assign) UIInterfaceOrientation orientationInternal;
@property (nonatomic, assign) BOOL horizontalFlipForFrontInternal;

@property (nonatomic, strong) AVCaptureDevice * videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput * videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * videoOutput;

@property (nonatomic, strong) KTVVPTimeComponents * timeComponents;
@property (nonatomic, strong) KTVVPFramePool * framePool;
@property (nonatomic, assign) BOOL didCallStartRecording;
@property (nonatomic, assign) NSInteger configurationCount;

@end

@implementation KTVVPVideoCamera

- (instancetype)init
{
    if (self = [super init])
    {
        _captureSession = [[AVCaptureSession alloc] init];
        _timeComponents = [[KTVVPTimeComponents alloc] init];
        
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
    NSLog(@"%s", __func__);
}

- (void)start
{
    if (_didCallStartRecording)
    {
        return;
    }
    _didCallStartRecording = YES;
    [self reloadOutput];
    [self reloadSessionPreset];
    [self reloadPosition];
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

- (void)reloadOutput
{
    [self beginConfiguration];
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    if ([_captureSession canAddOutput:_videoOutput])
    {
        [_captureSession addOutput:_videoOutput];
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
    _videoDevice = nil;
    NSArray * devices = nil;
    if (@available(iOS 10.0, *))
    {
        AVCaptureDeviceDiscoverySession * discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
        devices = discoverySession.devices;
    }
    else
    {
        devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    }
    for (AVCaptureDevice * device in devices)
    {
        if (device.position == _position)
        {
            _videoDevice = device;
        }
    }
    if (!_videoDevice)
    {
        _videoDevice = devices.firstObject;
        if (!_videoDevice)
        {
            _error = [NSError errorWithDomain:@"No vaild camera device." code:-1 userInfo:nil];
            return;
        }
    }
    [self beginConfiguration];
    if (_videoInput)
    {
        [_captureSession removeInput:_videoInput];
        _videoInput = nil;
    }
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_videoDevice error:nil];
    if ([_captureSession canAddInput:_videoInput])
    {
        [_captureSession addInput:_videoInput];
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


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.paused || !self.pipeline)
    {
        [_timeComponents putDroppedTimeStamp:presentationTimeStamp];
    }
    else
    {
        [_timeComponents putCurrentTimeStamp:presentationTimeStamp];
        if (!self.framePool)
        {
            self.framePool = [[KTVVPFramePool alloc] init];
        }
        KTVVPFrameCMSmapleBuffer * frame = [self.framePool frameWithKey:[KTVVPFrameCMSmapleBuffer key] factory:^__kindof KTVVPFrame *{
            KTVVPFrameCMSmapleBuffer * result = [[KTVVPFrameCMSmapleBuffer alloc] init];
            return result;
        }];
        frame.sampleBuffer = sampleBuffer;
        frame.timeStamp = _timeComponents.timeStamp;
        frame.rotationMode = [self rotationMode];
        frame.flipMode = [self flipMode];
        [self.pipeline inputFrame:frame fromSource:self];
        [frame unlock];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%s", __func__);
}

@end
