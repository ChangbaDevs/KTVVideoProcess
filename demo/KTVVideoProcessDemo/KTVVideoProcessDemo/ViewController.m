//
//  ViewController.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "ViewController.h"
#import <KTVVideoProcess/KTVVideoProcess.h>

@interface ViewController ()

@property (nonatomic, strong) KTVVPContext * context;
@property (nonatomic, strong) KTVVPCaptureSession * captureSession;
@property (nonatomic, strong) KTVVPSerialPipeline * pipeline;
@property (nonatomic, strong) KTVVPFrameView * frameView;
@property (nonatomic, strong) KTVVPFrameWriter * frameWriter;

@property (nonatomic, strong) KTVVPRGBFilter * RGBFilter;
@property (nonatomic, strong) KTVVPExposureFilter * exposureFilter;
@property (nonatomic, strong) KTVVPBrightnessFilter * brightnessFilter;
@property (nonatomic, strong) KTVVPBlackAndWhiteFilter * blackAndWhiteFilter;

@property (nonatomic, weak) IBOutlet UIImageView * snapshotImageView;

@end

@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self setup:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.frameView.frame = self.view.bounds;
}

- (void)applicationWillResignActiveNotification
{
    self.captureSession.paused = YES;
    [self.pipeline glFinish];
    [self recordFinishAction:nil];
    [self.pipeline waitUntilFinished];
    [self.frameView waitUntilFinished];
    [self.frameWriter waitUntilFinished];
}

- (void)applicationDidBecomeActiveNotification
{
    self.captureSession.paused = NO;
}

- (IBAction)setup:(UIButton *)sender
{
    self.context = [KTVVPContext sharedContext];
    
    NSArray <Class> * filterClasses = @[[KTVVPRGBFilter class],
                                        [KTVVPExposureFilter class],
                                        [KTVVPBrightnessFilter class],
                                        [KTVVPBlackAndWhiteFilter class],
                                        [KTVVPTransformFilter class]];
    self.pipeline = [[KTVVPSerialPipeline alloc] initWithContext:self.context filterClasses:filterClasses];
    __weak typeof(self) weakSelf = self;
    [self.pipeline setFilterConfigurationCallback:^(__kindof KTVVPFilter * filter, NSInteger index) {
        __weak typeof(weakSelf) self = weakSelf;
        if ([filter isKindOfClass:[KTVVPRGBFilter class]]) {
            self.RGBFilter = filter;
            self.RGBFilter.enable = NO;
            self.RGBFilter.red = 1.0;
            self.RGBFilter.green = 0.6;
            self.RGBFilter.blue = 1.0;
        } else if ([filter isKindOfClass:[KTVVPExposureFilter class]]) {
            self.exposureFilter = filter;
            self.exposureFilter.enable = NO;
            self.exposureFilter.exposure = 0.5;
        } else if ([filter isKindOfClass:[KTVVPBrightnessFilter class]]) {
            self.brightnessFilter = filter;
            self.brightnessFilter.enable = NO;
            self.brightnessFilter.brightness = 0.2;
        } else if ([filter isKindOfClass:[KTVVPBlackAndWhiteFilter class]]) {
            self.blackAndWhiteFilter = filter;
            self.blackAndWhiteFilter.enable = NO;
        }
    }];
    [self.pipeline setupIfNeeded];
    
    self.frameView = [[KTVVPFrameView alloc] initWithContext:self.context];
    self.frameView.frame = self.view.bounds;
    [self.view insertSubview:self.frameView atIndex:0];
    [self.pipeline addOutput:self.frameView];
    
    self.captureSession = [[KTVVPCaptureSession alloc] init];
    self.captureSession.pipeline = self.pipeline;
    self.captureSession.audioEnable = YES;
    [self.captureSession start];
}

- (IBAction)destory:(UIButton *)sender
{
    self.captureSession.pipeline = nil;
    self.captureSession.audioOutput = nil;
    self.captureSession = nil;
    [self.pipeline removeAllOutputs];
    self.pipeline = nil;
    [self.frameView removeFromSuperview];
    self.frameView = nil;
    [self.frameWriter cancel];
    self.frameWriter = nil;
    self.context = nil;
}

- (IBAction)snapshot:(UIButton *)sender
{
    __weak typeof(self) weakSelf = self;
    [self.frameView snapshot:^(UIImage * image) {
        weakSelf.snapshotImageView.image = image;
    }];
}

- (IBAction)changeToMirrorOn:(UIButton *)sender
{
    self.captureSession.horizontalFlipForFront = YES;
}

- (IBAction)changeToMirrorOff:(UIButton *)sender
{
    self.captureSession.horizontalFlipForFront = NO;
}

- (IBAction)changeTo1080p:(UIButton *)sender
{
    self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
}

- (IBAction)changeTo720p:(UIButton *)sender
{
    self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
}

- (IBAction)changeToFrontCamera:(UIButton *)sender
{
    self.captureSession.position = AVCaptureDevicePositionFront;
}

- (IBAction)changeToBackCamera:(UIButton *)sender
{
    self.captureSession.position = AVCaptureDevicePositionBack;
}

- (IBAction)captureStartAction:(UIButton *)sender
{
    [self.captureSession start];
}

- (IBAction)capturePauseAction:(UIButton *)sender
{
    self.captureSession.paused = YES;
}

- (IBAction)captureResumeAction:(UIButton *)sender
{
    self.captureSession.paused = NO;
}

- (IBAction)captureStopAction:(UIButton *)sender
{
    [self.captureSession stop];
}

- (IBAction)recordStartAction:(UIButton *)sender
{
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"KTVVideoProcess-temp.mov"];
    self.frameWriter = [[KTVVPFrameWriter alloc] init];
    self.frameWriter.outputFileURL = [NSURL fileURLWithPath:filePath];
    self.frameWriter.videoOutputSize = KTVVPSizeMake(720, 1280);
    self.frameWriter.videoEncodeDelayInterval = 0.0f;
    self.frameWriter.audioEnable = YES;
    [self.frameWriter setStartCallback:^(BOOL success) {
        NSLog(@"Record Started...");
    }];
    [self.frameWriter setFinishedCallback:^(BOOL success) {
        NSLog(@"Record Finished...");
    }];
    [self.frameWriter setCancelCallback:^(BOOL success) {
        NSLog(@"Record Canceled...");
    }];
    [self.frameWriter start];
    [self.pipeline addOutput:self.frameWriter];
    self.captureSession.audioOutput = self.frameWriter;
}

- (IBAction)recordPauseAction:(UIButton *)sender
{
    self.frameWriter.paused = YES;
}

- (IBAction)recordResumeAction:(UIButton *)sender
{
    self.frameWriter.paused = NO;
}

- (IBAction)recordFinishAction:(UIButton *)sender
{
    [self.frameWriter finish];
}

- (IBAction)recordCancelAction:(UIButton *)sender
{
    [self.frameWriter cancel];
}

- (IBAction)chooseFilterAction:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex)
    {
        case 0:
            [self enableFilter:nil];
            break;
        case 1:
            [self enableFilter:self.RGBFilter];
            break;
        case 2:
            [self enableFilter:self.exposureFilter];
            break;
        case 3:
            [self enableFilter:self.brightnessFilter];
            break;
        case 4:
            [self enableFilter:self.blackAndWhiteFilter];
            break;
    }
}

- (void)enableFilter:(__kindof KTVVPFilter *)filter
{
    NSArray <KTVVPFilter *> * filters = @[self.RGBFilter,
                                          self.exposureFilter,
                                          self.brightnessFilter,
                                          self.blackAndWhiteFilter];
    for (KTVVPFilter * obj in filters)
    {
        BOOL enable = obj == filter;
        obj.enable = enable;
    }
}

@end
