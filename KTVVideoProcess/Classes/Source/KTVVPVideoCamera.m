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

@property (nonatomic, strong) NSMutableArray <id <KTVVPInput>> * outputs;

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
    KTVVPFramePool * framePool = [_context framePoolForKey:[NSString stringWithFormat:@"%p", self]];
    KTVVPFrameCMSmapleBuffer * frame = [framePool frameWithKey:[KTVVPFrameCMSmapleBuffer key] factory:^__kindof KTVVPFrame *{
        KTVVPFrameCMSmapleBuffer * result = [[KTVVPFrameCMSmapleBuffer alloc] init];
        return result;
    }];
    frame.sampleBuffer = sampleBuffer;
    frame.rotationMode = KTVVPFrameRotationMode90;
    [self outputFrame:frame];
    [frame unlock];
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%s", __func__);
}


#pragma mark - KTVVPOutput

- (void)addInput:(id <KTVVPInput>)input
{
    if (!_outputs)
    {
        _outputs = [[NSMutableArray alloc] init];
    }
    [_outputs addObject:input];
}

- (void)removeInput:(id <KTVVPInput>)input
{
    [_outputs removeObject:input];
}

- (void)outputFrame:(KTVVPFrame *)frame
{
    for (id <KTVVPInput> obj in _outputs)
    {
        [obj putFrame:frame];
    }
}

@end
