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
#import "KTVVPToneCurveFilter.h"
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
    [self setup:nil];
}

- (IBAction)setup:(UIButton *)sender
{
    self.context = [[KTVVPContext alloc] init];
    
    self.frameView = [[KTVVPFrameView alloc] initWithContext:self.context];
    self.frameView.frame = self.view.bounds;
    [self.view insertSubview:self.frameView atIndex:0];
    
    KTVVPGLSize videoSize = {720, 720};
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ktvvptmp.mov"];
    self.frameWriter = [[KTVVPFrameWriter alloc] initWithContext:self.context videoSize:videoSize];
    self.frameWriter.outputFileURL = [NSURL fileURLWithPath:filePath];
    self.frameWriter.delayInterval = 0.0f;
    
    self.pipeline = [[KTVVPSerialPipeline alloc] initWithContext:self.context
                                                   filterClasses:@[[KTVVPToneCurveFilter class],
                                                                   [KTVVPSenseTimeFilter class],
                                                                   [KTVVPThroughFilter class]]];
    [self.pipeline setFilterConfigurationCallback:^(__kindof KTVVPFilter * filter, NSInteger filterIndexInPipiline, NSInteger pipelineIndex) {
        NSLog(@"%@, %ld, %ld", filter, filterIndexInPipiline, pipelineIndex);
    }];
    [self.pipeline addOutput:self.frameView];
    [self.pipeline addOutput:self.frameWriter];
    [self.pipeline setupIfNeeded];
    
    self.videoCamera = [[KTVVPVideoCamera alloc] initWithContext:self.context];
    self.videoCamera.pipeline = self.pipeline;
    
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
    [self.frameWriter setStartedCallback:^(BOOL success) {
        NSLog(@"Record Started...");
    }];
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
    [self.frameWriter setFinishedCallback:^(BOOL success) {
        NSLog(@"Record Finished...");
    }];
    [self.frameWriter finish];
}

- (IBAction)recordCancelAction:(UIButton *)sender
{
    [self.frameWriter setCanceledCallback:^(BOOL success) {
        NSLog(@"Record Canceled...");
    }];
    [self.frameWriter cancel];
}

@end
