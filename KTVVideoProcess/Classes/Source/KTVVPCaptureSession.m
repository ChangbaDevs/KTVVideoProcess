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

@interface KTVVPCaptureSession () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureDataOutputSynchronizerDelegate>

@property (nonatomic) BOOL horizontalFlipForFrontInternal;
@property (nonatomic) UIInterfaceOrientation orientationInternal;
@property (nonatomic, copy) AVCaptureSessionPreset sessionPresetInternal;
@property (nonatomic, copy) NSString *deviceTypeInternal;
@property (nonatomic) AVCaptureDevicePosition positionInternal;

@property (nonatomic, strong) AVCaptureDevice *audioDevice;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureDepthDataOutput *depthDataOutput;
@property (nonatomic, strong) AVCaptureDataOutputSynchronizer *dataSynchornizer;

@property (nonatomic, strong) dispatch_queue_t audioProcessingQueue;
@property (nonatomic, strong) dispatch_queue_t videoProcessingQueue;
@property (nonatomic, strong) KTVVPTimeComponents *audioTimeComponents;
@property (nonatomic, strong) KTVVPTimeComponents *videoTimeComponents;

@property (nonatomic, strong) KTVVPFramePool *framePool;
@property (nonatomic, assign) NSInteger configurationCount;
@property (nonatomic, assign) BOOL didCallPrepare;
@property (nonatomic, assign) BOOL didCallStart;

@end

@implementation KTVVPCaptureSession

- (instancetype)init
{
    if (self = [super init]) {
        _captureSession = [[AVCaptureSession alloc] init];
        _audioTimeComponents = [[KTVVPTimeComponents alloc] init];
        _videoTimeComponents = [[KTVVPTimeComponents alloc] init];
        _audioProcessingQueue = dispatch_queue_create("KTVVPCaptureSession-Audio", DISPATCH_QUEUE_SERIAL);
        _videoProcessingQueue = dispatch_queue_create("KTVVPCaptureSession-Video", DISPATCH_QUEUE_SERIAL);
        
        _horizontalFlipForFront = YES;
        _orientation = UIInterfaceOrientationPortrait;
        _sessionPreset = AVCaptureSessionPreset1280x720;
        _deviceType = nil;
        _position = AVCaptureDevicePositionFront;
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
    if (_didCallPrepare) {
        return;
    }
    _didCallPrepare = YES;
    [self beginConfiguration];
    [self reloadSessionPreset];
    [self reloadVideoConnection];
    [self reloadAudioConnection];
    [self commitConfiguration];
}

- (void)start
{
    if (_didCallStart) {
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
    if (_configurationCount <= 0) {
        _configurationCount = 0;
        [self reloadInternal];
    }
}


#pragma mark - Setup

- (void)reloadInternal
{
    _horizontalFlipForFrontInternal = _horizontalFlipForFront;
    _orientationInternal = _orientation;
    _sessionPresetInternal = _sessionPreset;
    _deviceTypeInternal = _deviceType;
    _positionInternal = _position;
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

- (void)reloadSessionPreset
{
    [self beginConfiguration];
    if ([_captureSession canSetSessionPreset:_sessionPreset]) {
        _captureSession.sessionPreset = _sessionPreset;
    }
    [self commitConfiguration];
}

- (void)reloadVideoConnection
{
    [self beginConfiguration];
    if (_videoDevice) {
        _videoDevice = nil;
    }
    if (_videoDeviceInput) {
        [_captureSession removeInput:_videoDeviceInput];
        _videoDeviceInput = nil;
    }
    if (_videoDataOutput) {
        [_captureSession removeOutput:_videoDataOutput];
        _videoDataOutput = nil;
    }
    if (_depthDataOutput) {
        [_captureSession removeOutput:_depthDataOutput];
        _depthDataOutput = nil;
    }
    if (_dataSynchornizer) {
        _dataSynchornizer = nil;
    }
    AVCaptureDevice *device = [self videoDeviceWithDeviceType:_deviceType position:_position];
    if (device) {
        AVCaptureDeviceInput  *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        if ([_captureSession canAddInput:input]) {
            AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
            [output setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)}];
            [output setSampleBufferDelegate:self queue:_videoProcessingQueue];
            if ([_captureSession canAddOutput:output]) {
                _videoDevice = device;
                _videoDeviceInput = input;
                _videoDataOutput = output;
                [_captureSession addInput:_videoDeviceInput];
                [_captureSession addOutput:_videoDataOutput];
                if ([_deviceType isEqualToString:AVCaptureDeviceTypeBuiltInTrueDepthCamera]) {
                    AVCaptureDepthDataOutput *output = [[AVCaptureDepthDataOutput alloc] init];
                    output.filteringEnabled = NO;
                    if ([_captureSession canAddOutput:output]) {
                        _depthDataOutput = output;
                        [_captureSession addOutput:_depthDataOutput];
                        int width = 320;
                        OSType type = kCVPixelFormatType_DepthFloat16;
                        for (AVCaptureDeviceFormat *obj in device.activeFormat.supportedDepthDataFormats) {
                            CMFormatDescriptionRef fd = obj.formatDescription;
                            if (CMFormatDescriptionGetMediaSubType(fd) == type &&
                                CMVideoFormatDescriptionGetDimensions(fd).width == width) {
                                [device lockForConfiguration:nil];
                                [device setActiveDepthDataFormat:obj];
                                [device unlockForConfiguration];
                                break;
                            }
                        }
                        _dataSynchornizer = [[AVCaptureDataOutputSynchronizer alloc] initWithDataOutputs:@[_videoDataOutput, _depthDataOutput]];
                        [_dataSynchornizer setDelegate:self queue:_videoProcessingQueue];
                    }
                }
            }
            
        }
    }
    [self commitConfiguration];
}

- (void)reloadAudioConnection
{
    [self beginConfiguration];
    if (_audioDevice) {
        _audioDevice = nil;
    }
    if (_audioDeviceInput) {
        [_captureSession removeInput:_audioDeviceInput];
        _audioDeviceInput = nil;
    }
    if (_audioDataOutput) {
        [_captureSession removeOutput:_audioDataOutput];
        _audioDataOutput = nil;
    }
    if (_audioEnable) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        if (device) {
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            if ([_captureSession canAddInput:input]) {
                AVCaptureAudioDataOutput *output = [[AVCaptureAudioDataOutput alloc] init];
                [output setSampleBufferDelegate:self queue:_audioProcessingQueue];
                if ([_captureSession canAddOutput:output]) {
                    _audioDevice = device;
                    _audioDeviceInput = input;
                    _audioDataOutput = output;
                    [_captureSession addInput:_audioDeviceInput];
                    [_captureSession addOutput:_audioDataOutput];
                }
            }
        }
    }
    [self commitConfiguration];
}

#pragma mark - Setter/Getter

- (void)setHorizontalFlipForFront:(BOOL)horizontalFlipForFront
{
    if (_horizontalFlipForFront != horizontalFlipForFront) {
        _horizontalFlipForFront = horizontalFlipForFront;
        [self reloadHorizontalFlipForFront];
    }
}

- (void)setOrientation:(UIInterfaceOrientation)orientation
{
    if (_orientation != orientation) {
        _orientation = orientation;
        [self reloadOrientation];
    }
}

- (BOOL)setSessionPreset:(AVCaptureSessionPreset)sessionPreset
{
    if ([_sessionPreset isEqualToString:sessionPreset]) {
        return YES;
    }
    if ([_captureSession canSetSessionPreset:sessionPreset]) {
        _sessionPreset = sessionPreset;
        [self reloadSessionPreset];
        return YES;
    }
    return YES;
}

- (BOOL)setDeviceType:(NSString *)deviceType
{
    return [self setPosition:_position deviceType:deviceType];
}

- (BOOL)setPosition:(AVCaptureDevicePosition)position
{
    return [self setPosition:position deviceType:_deviceType];
}

- (BOOL)setPosition:(AVCaptureDevicePosition)position deviceType:(NSString *)deviceType
{
    if (_deviceType == deviceType && _position == position) {
        return YES;
    }
    if ([self videoDeviceWithDeviceType:deviceType position:position]) {
        _position = position;
        _deviceType = deviceType;
        [self reloadVideoConnection];
        return YES;
    }
    return NO;
}

- (void)setAudioEnable:(BOOL)audioEnable
{
    if (_didCallStart) {
        return;
    }
    if (_audioEnable != audioEnable) {
        _audioEnable = audioEnable;
        [self reloadAudioConnection];
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
        && _horizontalFlipForFrontInternal) {
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

- (AVCaptureDevice *)videoDeviceWithDeviceType:(NSString *)deviceType position:(AVCaptureDevicePosition)position
{
    AVCaptureDevice *device = nil;
    if (deviceType) {
        device = [AVCaptureDevice defaultDeviceWithDeviceType:deviceType mediaType:AVMediaTypeVideo position:position];
    } else {
        NSArray *devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:_position].devices;
        for (AVCaptureDevice *obj in devices) {
            if (obj.position == _position) {
                device = obj;
            }
        }
    }
    return device;
}


#pragma mark - Configuration

- (void)setMinFrameDuration:(CMTime)minFrameDuration
{
    [self beginConfiguration];
    if ([_videoDevice lockForConfiguration:nil]) {
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
    if ([_videoDevice lockForConfiguration:nil]) {
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
    if ([_videoDevice lockForConfiguration:nil]) {
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
    if ([_videoDevice lockForConfiguration:nil]) {
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
    if ([_videoDevice lockForConfiguration:nil]) {
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
    if ([_videoDevice lockForConfiguration:nil]) {
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
    if ([_videoDevice lockForConfiguration:nil]) {
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
    AVCaptureConnection *connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    return connection.supportsVideoStabilization;
}

- (AVCaptureVideoStabilizationMode)activeVideoStabilizationMode
{
    AVCaptureConnection *connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    return connection.activeVideoStabilizationMode;
}

- (void)setPreferredVideoStabilizationMode:(AVCaptureVideoStabilizationMode)preferredVideoStabilizationMode
{
    AVCaptureConnection *connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.preferredVideoStabilizationMode = preferredVideoStabilizationMode;
}

- (AVCaptureVideoStabilizationMode)preferredVideoStabilizationMode
{
    AVCaptureConnection *connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    return connection.preferredVideoStabilizationMode;
}

#pragma mark - Process

- (void)processVideo:(CMSampleBufferRef)sampleBuffer depthData:(id)depthData
{
    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.paused) {
        [_videoTimeComponents putDroppedTimeStamp:presentationTimeStamp];
    } else {
        [_videoTimeComponents putCurrentTimeStamp:presentationTimeStamp];
        if (self.pipeline) {
            if (!_framePool) {
                _framePool = [[KTVVPFramePool alloc] init];
            }
            KTVVPCMSmapleBufferFrame *frame = [_framePool frameWithKey:[KTVVPCMSmapleBufferFrame key] factory:^__kindof KTVVPFrame *{
                KTVVPCMSmapleBufferFrame *result = [[KTVVPCMSmapleBufferFrame alloc] init];
                return result;
            }];
            frame.sampleBuffer = sampleBuffer;
            frame.timeStamp = _videoTimeComponents.timeStamp;
            frame.hostTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            frame.layout.rotationMode = [self rotationMode];
            frame.layout.flipMode = [self flipMode];
            frame.depthData = depthData;
            [self.pipeline inputFrame:frame fromSource:self];
            [frame unlock];
        }
    }
}

- (void)processAudio:(CMSampleBufferRef)sampleBuffer
{
    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.paused) {
        [_audioTimeComponents putDroppedTimeStamp:presentationTimeStamp];
    } else {
        [_audioTimeComponents putCurrentTimeStamp:presentationTimeStamp];
        if (_audioOutput) {
            KTVVPSample *sample = [[KTVVPSample alloc] init];
            sample.sampleBuffer = sampleBuffer;
            sample.timeStamp = _audioTimeComponents.timeStamp;
            sample.hostTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_audioOutput inputSample:sample fromSource:self];
        }
    }
}

#pragma mark - AVCaptureVideoD ataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (output == _videoDataOutput) {
        [self processVideo:sampleBuffer depthData:nil];
    } else if (output == _audioDataOutput) {
        [self processAudio:sampleBuffer];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (output == _videoDataOutput) {
        KTVVPLog(@"Video : %s", __func__);
    } else if (output == _audioDataOutput) {
        KTVVPLog(@"Audio : %s", __func__);
    }
}

#pragma mark - AVCaptureDataOutputSynchronizerDelegate

- (void)dataOutputSynchronizer:(AVCaptureDataOutputSynchronizer *)synchronizer didOutputSynchronizedDataCollection:(AVCaptureSynchronizedDataCollection *)synchronizedDataCollection
{
    AVCaptureSynchronizedSampleBufferData *sSampleBuffer = (AVCaptureSynchronizedSampleBufferData *)[synchronizedDataCollection synchronizedDataForCaptureOutput:_videoDataOutput];
    if (!sSampleBuffer || sSampleBuffer.sampleBufferWasDropped) {
        return;
    }
    AVDepthData *depthData = nil;
    AVCaptureSynchronizedDepthData *sDepthData = (AVCaptureSynchronizedDepthData *)[synchronizedDataCollection synchronizedDataForCaptureOutput:_depthDataOutput];
    if (sDepthData && !sDepthData.depthDataWasDropped) {
        depthData = sDepthData.depthData;
    }
    CMSampleBufferRef sampleBuffer = sSampleBuffer.sampleBuffer;
    [self processVideo:sampleBuffer depthData:depthData];
}

@end
