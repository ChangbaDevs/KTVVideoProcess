//
//  KTVVPExportSession.h
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/4.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPSerialPipeline.h"

@interface KTVVPExportSession : NSObject

/**
 *  Export config.
 *
 *  @property preferredFlag  The flag is to decide what type of track will be exported. Default value is KTVVPAVFlagAudioVideo.
 */
@property (nonatomic, copy) NSURL *sourceURL;
@property (nonatomic, copy) NSURL *destinationURL;
@property (nonatomic, strong) KTVVPSerialPipeline *pipeline;
@property (nonatomic, assign) KTVVPAVFlag preferredFlag;

/**
 *  Reader config.
 */
@property (nonatomic, copy) NSDictionary *readerAudioOutputSettings;
@property (nonatomic, copy) NSDictionary *readerVideoOutputSettings;

/**
 *  Writer config.
 *
 *  @property writerFileType  Default value is AVFileTypeMPEG4.
 */
@property (nonatomic, copy) AVFileType writerFileType;
@property (nonatomic, copy) NSDictionary *writerAudioOutputSettings;
@property (nonatomic, copy) NSDictionary *writerVideoOutputSettings;

/**
 *  Callback.
 *
 *  Not on main thread, don't block it.
 */
@property (nonatomic, copy) void (^progressCallback)(float progress);
@property (nonatomic, copy) void (^completionCallback)(NSURL *destinationURL, NSError *error);

#pragma mark - Trigger

- (void)start;
- (void)cancel;

@property (nonatomic, copy, readonly) NSError *error;

@end
