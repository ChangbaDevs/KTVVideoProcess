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

@property (nonatomic, strong) NSMutableArray <id <KTVVPInput>> * inputs;

@end

@implementation KTVVPVideoCamera

- (instancetype)initWithContext:(KTVVPContext *)context
{
    if (self = [super init])
    {
        _context = context;
    }
    return self;
}

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
    
    self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    KTVVPFrame * frame = [[KTVVPFrame alloc] initWithCMSmapleBuffer:sampleBuffer];
    [frame lock];
    for (id <KTVVPInput> obj in self.inputs)
    {
        [obj putFrame:frame];
    }
    [frame unlock];
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%s", __func__);
}


#pragma mark - KTVVPOutput

- (void)addInput:(id <KTVVPInput>)input
{
    if (input)
    {
        if (!self.inputs)
        {
            self.inputs = [[NSMutableArray alloc] init];
        }
        [self.inputs addObject:input];
    }
}

- (void)removeInput:(id <KTVVPInput>)input
{
    if (input)
    {
        [self.inputs removeObject:input];
    }
}

@end
