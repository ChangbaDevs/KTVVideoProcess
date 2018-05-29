//
//  KTVVPSample.m
//  KTVVideoProcess
//
//  Created by Single on 2018/4/27.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPSample.h"

@implementation KTVVPSample

- (instancetype)init
{
    if (self = [super init])
    {
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    [self clear];
}

- (void)setSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (sampleBuffer)
    {
        CFRetain(sampleBuffer);
    }
    [self clear];
    _sampleBuffer = sampleBuffer;
    if (_sampleBuffer)
    {
        _timeStamp = CMSampleBufferGetPresentationTimeStamp(_sampleBuffer);
        _duration = CMSampleBufferGetDuration(_sampleBuffer);
    }
}

- (void)clear
{
    if (_sampleBuffer)
    {
        CFRelease(_sampleBuffer);
        _sampleBuffer = NULL;
    }
    _timeStamp = kCMTimeInvalid;
    _duration = kCMTimeInvalid;
}

@end
