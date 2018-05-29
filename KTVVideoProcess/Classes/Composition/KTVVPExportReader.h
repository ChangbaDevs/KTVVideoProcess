//
//  KTVVPExportReader.h
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/4.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPDefines.h"
#import "KTVVPFrame.h"
#import "KTVVPSample.h"

@interface KTVVPExportReader : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)URL preferredFlag:(KTVVPAVFlag)preferredFlag;

/**
 *  Readonly properties.
 */
@property (nonatomic, copy, readonly) NSURL * URL;
@property (nonatomic, assign, readonly) KTVVPAVFlag preferredFlag;
@property (nonatomic, assign, readonly) KTVVPAVFlag actualFlag;
@property (nonatomic, assign, readonly) KTVVPSize size;
@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign, readonly) CMTimeRange audioTimeRange;
@property (nonatomic, assign, readonly) CMTimeRange videoTimeRange;

/**
 *  Output Config.
 */
@property (nonatomic, copy) NSDictionary * audioOutputSettings;
@property (nonatomic, copy) NSDictionary * videoOutputSettings;

/**
 *  Output data.
 */
- (KTVVPFrame *)nextFrame;
- (KTVVPSample *)nextSample;

#pragma mark - Trigger

- (void)start;

@property (nonatomic, copy, readonly) NSError * error;

@end
