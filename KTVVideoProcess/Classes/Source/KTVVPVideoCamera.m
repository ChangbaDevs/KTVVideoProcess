//
//  KTVVPVideoCamera.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPVideoCamera.h"
#import <AVFoundation/AVFoundation.h>

@interface KTVVPVideoCamera () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession * captureSession;
@property (nonatomic, strong) AVCaptureDevice * videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput * videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * videoOutput;

@end

@implementation KTVVPVideoCamera

- (void)startRunning
{
    self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!self.videoDevice)
    {
        return;
    }
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:nil];
    [self.captureSession addInput:self.videoInput];
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.videoOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    [self.captureSession addOutput:self.videoOutput];
    
    self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%@", sampleBuffer);
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%s", __func__);
}

@end
