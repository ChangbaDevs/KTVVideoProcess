//
//  KTVVPCaptureSession.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPSource.h"
#import <AVFoundation/AVFoundation.h>
#import "KTVVPSampleInput.h"

@interface KTVVPCaptureSession : KTVVPSource

@property (nonatomic, copy, readonly) NSError * error;
@property (nonatomic, strong, readonly) AVCaptureSession * captureSession;

/**
 *  @property sessionPreset           Default value is AVCaptureSessionPreset1280x720.
 *  @property orientation             Default value is UIInterfaceOrientationPortrait.
 *  @property position                Default value is AVCaptureDevicePositionFront.
 *  @property horizontalFlipForFront  Default value is YES.
 */
@property (nonatomic, copy) AVCaptureSessionPreset sessionPreset;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) AVCaptureDevicePosition position;
@property (nonatomic, assign) BOOL horizontalFlipForFront;

/**
 *  Frame Duration.
 */
@property (nonatomic, assign) CMTime minFrameDuration;
@property (nonatomic, assign) CMTime maxFrameDuration;

/**
 *  Torch mode.
 */
@property (nonatomic, assign, readonly) BOOL torchSupported;
@property (nonatomic, assign) AVCaptureTorchMode torchMode;

/**
 *  Focus mode.
 */
- (BOOL)isFocusModeSupported:(AVCaptureFocusMode)focusMode;
@property (nonatomic, assign) AVCaptureFocusMode focusMode;
@property (nonatomic, assign, readonly) BOOL focusPointOfInterestSupported;
@property (nonatomic, assign) CGPoint focusPointOfInterest;

/**
 *  Exposure mode.
 */
- (BOOL)isExposureModeSupported:(AVCaptureExposureMode)exposureMode;
@property (nonatomic, assign) AVCaptureExposureMode exposureMode;
@property (nonatomic, assign, readonly) BOOL exposurePointOfInterestSupported;
@property (nonatomic, assign) CGPoint exposurePointOfInterest;

/**
 *  Stabilization mode.
 */
@property (nonatomic, assign, readonly) BOOL videoStabilizationSupported;
@property (nonatomic, assign, readonly) AVCaptureVideoStabilizationMode activeVideoStabilizationMode;
@property (nonatomic, assign) AVCaptureVideoStabilizationMode preferredVideoStabilizationMode;

/**
 *  Configuration locking.
 */
- (void)beginConfiguration;
- (void)commitConfiguration;

/**
 *  Audio config.
 */
@property (nonatomic, assign) BOOL audioEnable;
@property (atomic, strong) id <KTVVPSampleInput> audioOutput;

@end
