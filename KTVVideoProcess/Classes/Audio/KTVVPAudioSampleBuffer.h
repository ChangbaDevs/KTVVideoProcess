//
//  KTVVPAudioSampleBuffer.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/27.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface KTVVPAudioSampleBuffer : NSObject

@property (nonatomic, assign) CMTime timeStamp;
@property (nonatomic, assign) CMTime duration;

@property (nonatomic, assign) CMSampleBufferRef sampleBuffer;

@end
