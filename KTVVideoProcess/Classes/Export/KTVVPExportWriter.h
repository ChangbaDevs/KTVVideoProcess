//
//  KTVVPExportWriter.h
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/4.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPSample.h"
#import "KTVVPFrame.h"

@interface KTVVPExportWriter : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL size:(KTVVPSize)size flag:(KTVVPAVFlag)flag;

/**
 *  Output Config.
 *
 *  @property fileType  Default value is AVFileTypeMPEG4.
 */
@property (nonatomic, copy) AVFileType fileType;
@property (nonatomic, copy) NSDictionary *audioOutputSettings;
@property (nonatomic, copy) NSDictionary *videoOutputSettings;

/**
 *  Input data.
 */
- (void)appendWhenReadyWithFrameCallback:(void (^)(void))frameCallback sampleCallback:(void (^)(void))sampleCallback finishCallback:(void (^)(void))finishCallback;

@property (nonatomic, assign, readonly) BOOL readyForMoreFrame;
@property (nonatomic, assign, readonly) BOOL readyForMoreSample;

- (void)appendFrame:(KTVVPFrame *)frame;
- (void)appendSample:(KTVVPSample *)sample;

- (void)markFrameAsFinished;
- (void)markSampleAsFinished;

#pragma mark - Trigger

- (void)start;
- (void)cancel;

@property (nonatomic, copy, readonly) NSError *error;

@end
