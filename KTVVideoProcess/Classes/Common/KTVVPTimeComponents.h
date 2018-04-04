//
//  KTVVPTimeComponents.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/28.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface KTVVPTimeComponents : NSObject

@property (nonatomic, assign, readonly) CMTime timeStamp;
@property (nonatomic, assign, readonly) CMTime previousTimeStamp;
@property (nonatomic, assign, readonly) CMTime firstTimeStamp;
@property (nonatomic, assign, readonly) CMTime duration;

- (void)putDroppedTimeStamp:(CMTime)timeStamp;
- (void)putCurrentTimeStamp:(CMTime)timeStamp;

@end
