//
//  KTVVPVideoCamera.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPVideoCamera.h"
#import <AVFoundation/AVFoundation.h>
#import "KTVVPFramePool.h"
#import "KTVVPFrameCMSmapleBuffer.h"

@interface KTVVPVideoCamera () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession * captureSession;
@property (nonatomic, strong) AVCaptureDevice * videoDevice;
@property (nonatomic, strong) AVCaptureDeviceInput * videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * videoOutput;

@end

@implementation KTVVPVideoCamera

- (void)start
{
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice * device in devices)
    {
        if ([device position] == AVCaptureDevicePositionFront)
        {
            _videoDevice = device;
        }
    }
    if (!_videoDevice)
    {
        return;
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession beginConfiguration];
    
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:nil];
    [_captureSession addInput:_videoInput];
    
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    [_captureSession addOutput:_videoOutput];
    
    _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    [_captureSession commitConfiguration];
    [_captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.pipeline)
    {
        KTVVPFramePool * framePool = [self.context framePoolForKey:[NSString stringWithFormat:@"%p", self]];
        KTVVPFrameCMSmapleBuffer * frame = [framePool frameWithKey:[KTVVPFrameCMSmapleBuffer key] factory:^__kindof KTVVPFrame *{
            KTVVPFrameCMSmapleBuffer * result = [[KTVVPFrameCMSmapleBuffer alloc] init];
            return result;
        }];
        frame.sampleBuffer = sampleBuffer;
        frame.time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        frame.rotationMode = KTVVPRotationMode90;
        [self.pipeline inputFrame:frame fromSource:self];
        [frame unlock];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%s", __func__);
}

@end
