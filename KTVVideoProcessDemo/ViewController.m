//
//  ViewController.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "ViewController.h"
#import "KTVVPVideoCamera.h"
#import "KTVVPFrameView.h"
#import "KTVVPProcessor.h"
#import "KTVVPFilter.h"
#import "KTVVPPassThroughFilter.h"

@interface ViewController ()

@property (nonatomic, strong) KTVVPContext * context;
@property (nonatomic, strong) KTVVPVideoCamera * videoCamera;
@property (nonatomic, strong) KTVVPProcessor * processor;
@property (nonatomic, strong) KTVVPFrameView * frameView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[KTVVPContext alloc] init];
    
    self.frameView = [[KTVVPFrameView alloc] initWithContext:self.context];
    self.frameView.frame = self.view.bounds;
    [self.view addSubview:self.frameView];
    
    self.processor = [[KTVVPProcessor alloc] initWithContext:self.context
                                               filterClasses:@[[KTVVPPassThroughFilter class]]];
    [self.processor setupIfNeed];
    [self.processor addInput:self.frameView];
    
    self.videoCamera = [[KTVVPVideoCamera alloc] initWithContext:self.context];
    [self.videoCamera addInput:self.processor];
    [self.videoCamera startRunning];
}

@end
