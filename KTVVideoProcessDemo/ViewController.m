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
#import "KTVVPFilterToneCurve.h"
#import "KTVVPSenseTimeFilter.h"

@interface ViewController ()

@property (nonatomic, strong) KTVVPContext * context;
@property (nonatomic, strong) KTVVPVideoCamera * videoCamera;
@property (nonatomic, strong) KTVVPSerialPipeline * pipeline;
@property (nonatomic, strong) KTVVPFrameView * frameView;
@property (nonatomic, strong) KTVVPFrameWriter * frameWriter;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[KTVVPContext alloc] init];
    
    self.frameView = [[KTVVPFrameView alloc] initWithContext:self.context];
    self.frameView.frame = self.view.bounds;
    [self.view insertSubview:self.frameView atIndex:0];
    
    KTVVPGLSize videoSize = {720, 1280};
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ktvvptmp.mov"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    self.frameWriter = [[KTVVPFrameWriter alloc] initWithContext:self.context videoSize:videoSize];
    self.frameWriter.outputFileURL = [NSURL fileURLWithPath:filePath];
//    self.frameWriter.asyncDelayInterval = 0.06;
    
    self.pipeline = [[KTVVPSerialPipeline alloc] initWithContext:self.context
                                                   filterClasses:@[[KTVVPFilterToneCurve class],
                                                                   [KTVVPThroughFilter class]]];
    [self.pipeline addOutput:self.frameView];
    [self.pipeline addOutput:self.frameWriter];
    [self.pipeline setupIfNeeded];
    
    self.videoCamera = [[KTVVPVideoCamera alloc] initWithContext:self.context];
    self.videoCamera.pipeline = self.pipeline;
    [self.videoCamera start];
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
    [self.frameWriter startRecording];
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
    [self.frameWriter finishRecordingWithCompletionHandler:^(BOOL success) {
        NSLog(@"Record Finished...");
    }];
}

- (IBAction)recordCancelAction:(UIButton *)sender
{
    [self.frameWriter cancelRecordingWithCompletionHandler:^(BOOL success) {
        NSLog(@"Record Canceled...");
    }];
}

@end
