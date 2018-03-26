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
#import "KTVVPPassThroughFilter.h"
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
    [self.view addSubview:self.frameView];
    
    KTVVPGLSize videoSize = {1280, 720};
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ktvvptmp.mov"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    self.frameWriter = [[KTVVPFrameWriter alloc] initWithContext:self.context videoSize:videoSize];
    self.frameWriter.outputFileURL = [NSURL fileURLWithPath:filePath];
//    self.frameWriter.asyncDelayInterval = 0.06;
    [self.frameWriter startRecording];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.frameWriter.paused = YES;
//        NSLog(@"Writer did paused.");
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            self.frameWriter.paused = NO;
//            NSLog(@"Writer did restart.");
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                NSLog(@"Writer will call finish.");
                [self.frameWriter finishRecordingWithCompletionHandler:^(BOOL success) {
                    NSLog(@"Writer Success, %d", success);
                }];
//            });
//        });
    });
    
    self.pipeline = [[KTVVPSerialPipeline alloc] initWithContext:self.context
                                                   filterClasses:@[[KTVVPFilterToneCurve class],
                                                                   [KTVVPSenseTimeFilter class]]];
    [self.pipeline addOutput:self.frameView];
    [self.pipeline addOutput:self.frameWriter];
    [self.pipeline setupIfNeeded];
    
    self.videoCamera = [[KTVVPVideoCamera alloc] initWithContext:self.context];
    self.videoCamera.pipeline = self.pipeline;
    [self.videoCamera start];
}

@end
