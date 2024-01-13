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
 *  @property horizontalFlipForFront Default value is YES.
 *  @property orientation            Default value is UIInterfaceOrientationPortrait.
 */
@property (nonatomic) BOOL horizontalFlipForFront;
@property (nonatomic) UIInterfaceOrientation orientation;

/**
 *  @property sessionPreset           Default value is AVCaptureSessionPreset1280x720.
 */
@property (nonatomic, copy, readonly) AVCaptureSessionPreset sessionPreset;
- (BOOL)setSessionPreset:(AVCaptureSessionPreset)sessionPreset;

/**
 *  @property deviceType Default value is nil.
 *  @property position   Default value is AVCaptureDevicePositionFront.
 */
@property (nonatomic, copy, readonly) NSString * deviceType;
@property (nonatomic, readonly) AVCaptureDevicePosition position;
- (BOOL)setDeviceType:(NSString *)deviceType;
- (BOOL)setPosition:(AVCaptureDevicePosition)position;
- (BOOL)setPosition:(AVCaptureDevicePosition)position deviceType:(NSString *)deviceType;

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
@property (nonatomic, assign) BOOL audioEnable;                     // This property must be set befor the source starts.
@property (atomic, strong) id <KTVVPSampleInput> audioOutput;       // This property can be set at any time.

@end
