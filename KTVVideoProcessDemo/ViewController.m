//
//  ViewController.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "ViewController.h"
#import "KTVVPVideoCamera.h"
#import "KTVVPSerialPipeline.h"
#import "KTVVPConcurrentPipeline.h"
#import "KTVVPFrameView.h"
#import "KTVVPFrameWriter.h"
#import "KTVVPFilter.h"
#import "KTVVPThroughFilter.h"

@interface ViewController ()

@property (nonatomic, strong) KTVVPContext * context;
@property (nonatomic, strong) KTVVPVideoCamera * videoCamera;
@property (nonatomic, strong) KTVVPSerialPipeline * pipeline;
@property (nonatomic, strong) KTVVPFrameView * frameView;
@property (nonatomic, strong) KTVVPFrameWriter * frameWriter;

@property (weak, nonatomic) IBOutlet UIImageView * snapshotImageView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.frameView.frame = self.view.bounds;
}

- (IBAction)setup:(UIButton *)sender
{
    // Context
    self.context = [[KTVVPContext alloc] init];
    
    // View
    self.frameView = [[KTVVPFrameView alloc] initWithContext:self.context];
    self.frameView.frame = self.view.bounds;
    [self.view insertSubview:self.frameView atIndex:0];
    
    // Writer
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"KTVVideoProcess_temp.mov"];
    self.frameWriter = [[KTVVPFrameWriter alloc] init];
    self.frameWriter.outputFileURL = [NSURL fileURLWithPath:filePath];
    self.frameWriter.videoOutputSize = KTVVPSizeMake(720, 1280);
    self.frameWriter.delayInterval = 0.0f;
    [self.frameWriter setStartCallback:^(BOOL success) {
        NSLog(@"Record Started...");
    }];
    [self.frameWriter setFinishedCallback:^(BOOL success) {
        NSLog(@"Record Finished...");
    }];
    [self.frameWriter setCancelCallback:^(BOOL success) {
        NSLog(@"Record Canceled...");
    }];
    
    // Pipeline
    self.pipeline = [[KTVVPSerialPipeline alloc] initWithContext:self.context
                                                   filterClasses:@[[KTVVPThroughFilter class]]];
    [self.pipeline setFilterConfigurationCallback:^(__kindof KTVVPFilter * filter, NSInteger filterIndexInPipiline, NSInteger pipelineIndex) {
        NSLog(@"%@, %ld, %ld", filter, filterIndexInPipiline, pipelineIndex);
    }];
    [self.pipeline addOutput:self.frameView];
    [self.pipeline addOutput:self.frameWriter];
    [self.pipeline setupIfNeeded];
    
    // Camera
    self.videoCamera = [[KTVVPVideoCamera alloc] init];
    self.videoCamera.pipeline = self.pipeline;
    
    // Start
    [self.frameWriter start];
    [self.videoCamera start];
}

- (IBAction)destory:(UIButton *)sender
{
    [self.frameView removeFromSuperview];
    self.pipeline = nil;
    self.frameView = nil;
    self.frameWriter = nil;
    self.videoCamera = nil;
    self.context = nil;
}

- (IBAction)snapshot:(UIButton *)sender
{
    [self.frameView snapshot:^(UIImage * image) {
        self.snapshotImageView.image = image;
    }];
}

- (IBAction)changeToMirrorOn:(UIButton *)sender
{
    self.videoCamera.horizontalFlipForFront = YES;
}

- (IBAction)changeToMirrorOff:(UIButton *)sender
{
    self.videoCamera.horizontalFlipForFront = NO;
}

- (IBAction)changeTo1080p:(UIButton *)sender
{
    self.videoCamera.sessionPreset = AVCaptureSessionPreset1920x1080;
}

- (IBAction)changeTo720p:(UIButton *)sender
{
    self.videoCamera.sessionPreset = AVCaptureSessionPreset1280x720;
}

- (IBAction)changeToFrontCamera:(UIButton *)sender
{
    self.videoCamera.position = AVCaptureDevicePositionFront;
}

- (IBAction)changeToBackCamera:(UIButton *)sender
{
    self.videoCamera.position = AVCaptureDevicePositionBack;
}

- (IBAction)captureStartAction:(UIButton *)sender
{
    [self.videoCamera start];
}

- (IBAction)capturePauseAction:(UIButton *)sender
{
    self.videoCamera.paused = YES;
}

- (IBAction)captureResumeAction:(UIButton *)sender
{
    self.videoCamera.paused = NO;
}

- (IBAction)captureStopAction:(UIButton *)sender
{
    [self.videoCamera stop];
}

- (IBAction)recordStartAction:(UIButton *)sender
{
    [self.frameWriter start];
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

@end
