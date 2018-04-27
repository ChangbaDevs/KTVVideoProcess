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

@interface KTVVPVideoCamera () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, copy) AVCaptureSessionPreset sessionPresetInternal;
@property (nonatomic, assign) AVCaptureDevicePosition positionInternal;
@property (nonatomic, assign) UIInterfaceOrientation orientationInternal;
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
@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didCallStart;
@property (nonatomic, assign) NSInteger configurationCount;

@end

@implementation KTVVPVideoCamera

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
    NSLog(@"%s", __func__);
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
    if (!self.videoProcessingQueue)
    {
        self.videoProcessingQueue = dispatch_queue_create("KTVVPVideoCamera-Video", DISPATCH_QUEUE_SERIAL);
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
    if (_audioOutput)
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
            if (!self.audioProcessingQueue)
            {
                self.audioProcessingQueue = dispatch_queue_create("KTVVPVideoCamera-Audio", DISPATCH_QUEUE_SERIAL);
            }
            _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
            [_audioDataOutput setSampleBufferDelegate:self queue:self.audioProcessingQueue];
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

- (void)setAudioOutput:(id <KTVVPAudioInput>)audioOutput
{
    if (_audioOutput != audioOutput)
    {
        _audioOutput = audioOutput;
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


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (output == _videoDataOutput)
    {
        if (self.paused || !self.pipeline)
        {
            [_videoTimeComponents putDroppedTimeStamp:presentationTimeStamp];
        }
        else
        {
            [_videoTimeComponents putCurrentTimeStamp:presentationTimeStamp];
            if (!self.framePool)
            {
                self.framePool = [[KTVVPFramePool alloc] init];
            }
            KTVVPFrameCMSmapleBuffer * frame = [self.framePool frameWithKey:[KTVVPFrameCMSmapleBuffer key] factory:^__kindof KTVVPFrame *{
                KTVVPFrameCMSmapleBuffer * result = [[KTVVPFrameCMSmapleBuffer alloc] init];
                return result;
            }];
            frame.sampleBuffer = sampleBuffer;
            frame.timeStamp = _videoTimeComponents.timeStamp;
            frame.layout.rotationMode = [self rotationMode];
            frame.layout.flipMode = [self flipMode];
            [self.pipeline inputFrame:frame fromSource:self];
            [frame unlock];
        }
    }
    else if (output == _audioDataOutput)
    {
        if (self.paused || !self.audioOutput)
        {
            [_audioTimeComponents putDroppedTimeStamp:presentationTimeStamp];
        }
        else
        {
            [_audioTimeComponents putCurrentTimeStamp:presentationTimeStamp];
            KTVVPAudioSampleBuffer * audioSampleBuffer = [[KTVVPAudioSampleBuffer alloc] init];
            audioSampleBuffer.sampleBuffer = sampleBuffer;
            audioSampleBuffer.timeStamp = _audioTimeComponents.timeStamp;
            [self.audioOutput inputAudioSampleBuffer:audioSampleBuffer fromSource:self];
        }
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (output == _videoDataOutput)
    {
        NSLog(@"Video : %s", __func__);
    }
    else if (output == _audioDataOutput)
    {
        NSLog(@"Audio : %s", __func__);
    }
}

@end
