//
//  KTVVPAVPlayerItemVideoOutput.h
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/3.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPSource.h"
#import <AVFoundation/AVFoundation.h>

@interface KTVVPAVPlayerItemVideoOutput : KTVVPSource

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem;

@end
