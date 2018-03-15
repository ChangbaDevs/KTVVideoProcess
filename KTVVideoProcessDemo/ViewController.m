//
//  ViewController.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "ViewController.h"
#import "KTVVPVideoCamera.h"

@interface ViewController ()

@property (nonatomic, strong) KTVVPVideoCamera * videoCamera;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.videoCamera = [[KTVVPVideoCamera alloc] init];
    [self.videoCamera startRunning];
}

@end
