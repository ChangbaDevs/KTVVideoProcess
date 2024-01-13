//
//  KTVVPTimeComponents.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/28.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPTimeComponents.h"

@interface KTVVPTimeComponents ()

@property (nonatomic, assign) CMTime deltaInterval;
@property (nonatomic, assign) CMTime firstDroppedTimeStamp;

@end

@implementation KTVVPTimeComponents

- (instancetype)init
{
    if (self = [super init]) {
        _timeStamp = kCMTimeZero;
        _previousTimeStamp = kCMTimeZero;
        _firstTimeStamp = kCMTimeInvalid;
        _duration = kCMTimeZero;
        _deltaInterval = kCMTimeZero;
        _firstDroppedTimeStamp = kCMTimeInvalid;
    }
    return self;
}

- (void)putDroppedTimeStamp:(CMTime)timeStamp
{
    if (CMTIME_IS_INVALID(_firstDroppedTimeStamp)) {
        _firstDroppedTimeStamp = timeStamp;
    }
}

- (void)putCurrentTimeStamp:(CMTime)timeStamp
{
    if (CMTIME_IS_VALID(_firstDroppedTimeStamp)) {
        CMTime currentDeltaInterval = CMTimeSubtract(timeStamp, _firstDroppedTimeStamp);
        _deltaInterval = CMTimeAdd(_deltaInterval, currentDeltaInterval);
        _firstDroppedTimeStamp = kCMTimeInvalid;
    }
    _previousTimeStamp = _timeStamp;
    _timeStamp = CMTimeSubtract(timeStamp, _deltaInterval);
    if (CMTIME_IS_INVALID(_firstTimeStamp)) {
        _firstTimeStamp = _timeStamp;
    }
    _duration = CMTimeSubtract(_timeStamp, _firstTimeStamp);
}

@end
