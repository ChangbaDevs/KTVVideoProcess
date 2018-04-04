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

@interface KTVVPFrameWriter : NSObject <KTVVPFrameInput>

@property (nonatomic, copy, readonly) NSError * error;

@property (nonatomic, copy) NSURL * outputFileURL;
@property (nonatomic, copy) AVFileType outputFileType;               // default is AVFileTypeQuickTimeMovie.

@property (nonatomic, copy) NSDictionary * videoOutputSettings;
@property (nonatomic, copy) AVVideoCodecType videoOutputCodec;       // default is AVVideoCodecH264.
@property (nonatomic, copy) NSString * videoOutputScalingMode;       // default is AVVideoScalingModeResizeAspectFill.
@property (nonatomic, assign) KTVVPSize videoOutputSize;
@property (nonatomic, assign) CGAffineTransform videoOutputTransform;

@property (nonatomic, copy) NSDictionary * videoSourcePixelBufferAttributes;
@property (nonatomic, assign) NSInteger videoSourcePixelFormat;      // default is kCVPixelFormatType_32BGRA.

@property (nonatomic, assign) NSTimeInterval delayInterval;          // default is 0.


#pragma mark - Control

@property (atomic, copy) void (^startCallback)(BOOL success);
@property (atomic, copy) void (^finishedCallback)(BOOL success);
@property (atomic, copy) void (^cancelCallback)(BOOL success);

@property (atomic, assign) BOOL paused;

- (void)start;
- (void)finish;
- (void)cancel;

@end
