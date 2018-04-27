//
//  KTVVPAudioSampleBuffer.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/27.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPAudioSampleBuffer.h"

@implementation KTVVPAudioSampleBuffer

- (void)dealloc
{
    if (_sampleBuffer)
    {
        CFRelease(_sampleBuffer);
        _sampleBuffer = NULL;
    }
}

- (void)setSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (sampleBuffer)
    {
        CFRetain(sampleBuffer);
    }
    _sampleBuffer = sampleBuffer;
    if (_sampleBuffer)
    {
        _duration = CMSampleBufferGetDuration(_sampleBuffer);
    }
}

@end
