//
//  KTVVPFrameWriter.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/21.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPContext.h"
#import "KTVVPFrameInput.h"
#import "KTVVPAudioInput.h"

@interface KTVVPFrameWriter : NSObject <KTVVPFrameInput, KTVVPAudioInput>

@property (nonatomic, copy, readonly) NSError * error;
@property (nonatomic, assign, readonly) NSTimeInterval duration;


#pragma mark - File

@property (nonatomic, copy) NSURL * outputFileURL;
@property (nonatomic, copy) AVFileType outputFileType;               // default is AVFileTypeMPEG4.


#pragma mark - Video

@property (nonatomic, assign) KTVVPSize videoOutputSize;
@property (nonatomic, copy)   NSString * videoOutputScalingMode;                // default is AVVideoScalingModeResizeAspectFill.
@property (nonatomic, assign) NSTimeInterval videoEncodeDelayInterval;          // default is 0.
@property (nonatomic, assign) CGAffineTransform videoOutputTransform;


@property (nonatomic, copy) NSDictionary * videoOutputSettings;
@property (nonatomic, copy) NSDictionary * videoSourcePixelBufferAttributes;


#pragma mark - Audio

@property (nonatomic, assign) BOOL audioEnable;
@property (nonatomic, strong) NSDictionary * audioOutputSettings;


#pragma mark - Control

@property (atomic, copy) void (^startCallback)(BOOL success);
@property (atomic, copy) void (^finishedCallback)(BOOL success);
@property (atomic, copy) void (^cancelCallback)(BOOL success);

@property (atomic, assign) BOOL paused;

- (void)start;
- (void)finish;
- (void)cancel;

@end
