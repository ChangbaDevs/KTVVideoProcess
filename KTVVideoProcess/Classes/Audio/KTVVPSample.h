//
//  KTVVPSample.h
//  KTVVideoProcess
//
//  Created by Single on 2018/4/27.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface KTVVPSample : NSObject

/**
 *  Basic information.
 */
@property (nonatomic, assign) CMTime timeStamp;
@property (nonatomic, assign) CMTime duration;

/**
 *  Containing data.
 */
@property (nonatomic, assign) CMSampleBufferRef sampleBuffer;

@end
