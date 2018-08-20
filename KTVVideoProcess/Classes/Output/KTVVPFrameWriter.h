//
//  KTVVPFrameWriter.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/21.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPFrameInput.h"
#import "KTVVPSampleInput.h"

@interface KTVVPFrameWriter : NSObject <KTVVPFrameInput, KTVVPSampleInput>

/**
 *  File config.
 *
 *  @property outputFileType  Default value is AVFileTypeMPEG4.
 */
@property (nonatomic, copy) NSURL * outputFileURL;
@property (nonatomic, copy) AVFileType outputFileType;

/**
 *  Video config.
 *
 *  @property videoEncodeDelayInterval  Default value is AVFileTypeMPEG4.
 *  @property videoOutputBitRate        Default value is 0.
 *  @property videoOutputScalingMode    Default value is AVVideoScalingModeResizeAspectFill.
 */
@property (nonatomic, assign) KTVVPSize videoOutputSize;
@property (nonatomic, assign) NSTimeInterval videoEncodeDelayInterval;
@property (nonatomic, assign) CGAffineTransform videoOutputTransform;
@property (nonatomic, assign) NSInteger videoOutputBitRate;
@property (nonatomic, copy) NSString * videoOutputScalingMode;
@property (nonatomic, copy) NSDictionary * videoOutputSettings;
@property (nonatomic, copy) NSDictionary * videoSourcePixelBufferAttributes;

/**
 *  Audio config.
 */
@property (nonatomic, assign) BOOL audioEnable;
@property (nonatomic, strong) NSDictionary * audioOutputSettings;

/**
 *  Callback.
 */
@property (atomic, copy) void (^startCallback)(BOOL success);
@property (atomic, copy) void (^finishedCallback)(BOOL success);
@property (atomic, copy) void (^cancelCallback)(BOOL success);
@property (atomic, copy) void (^appendedFrameCallback)(KTVVPFrame * frame);
@property (atomic, copy) void (^appendedSampleCallback)(KTVVPSample * sample);

/**
 *  Duration of video track.
 */
@property (nonatomic, assign, readonly) CMTime duration;

#pragma mark - Trigger

@property (atomic, assign) BOOL paused;

- (void)start;
- (void)finish;
- (void)cancel;

@property (nonatomic, copy, readonly) NSError * error;

/**
 *  Block current thread until finished all operations.
 */
- (void)waitUntilFinished;

@end
