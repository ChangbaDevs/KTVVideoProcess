//
//  KTVVPAVPlayerItemVideoOutput.m
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/3.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPAVPlayerItemVideoOutput.h"
#import "KTVVPFramePool.h"
#import "KTVVPCVPixelBufferFrame.h"

@interface KTVVPAVPlayerItemVideoOutput () <AVPlayerItemOutputPullDelegate>

@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerItemVideoOutput *playerItemVideoOutput;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastFrameTime;
@property (nonatomic, strong) KTVVPFramePool *framePool;
@property (nonatomic, assign) BOOL didCallStart;

@end

@implementation KTVVPAVPlayerItemVideoOutput

- (instancetype)initWithPlayerItem:(AVPlayerItem *)playerItem
{
    if (self = [super init]) {
        _playerItem = playerItem;
    }
    return self;
}

- (void)start
{
    if (_didCallStart) {
        return;
    }
    _didCallStart = YES;
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = YES;
    NSDictionary *pixelBuffer = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
    _playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffer];
    [_playerItemVideoOutput setDelegate:self queue:dispatch_get_main_queue()];
    _playerItemVideoOutput.suppressesPlayerRendering = YES;
    [_playerItem addOutput:_playerItemVideoOutput];
    [_playerItemVideoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.03];
}

- (void)stop
{
    if (_displayLink) {
        _displayLink.paused = YES;
        [_displayLink invalidate];
        _displayLink = nil;
    }
    if (_playerItem && _playerItemVideoOutput) {
        [_playerItem removeOutput:_playerItemVideoOutput];
        _playerItem = nil;
        _playerItemVideoOutput = nil;
    }
}

- (void)displayLinkCallback
{
    if (self.paused) {
        return;
    }
    CFTimeInterval nextVSync = _displayLink.timestamp + _displayLink.duration;
    CMTime outputItemTime = [_playerItemVideoOutput itemTimeForHostTime:nextVSync];
    BOOL hasNewPixelBuffer = [_playerItemVideoOutput hasNewPixelBufferForItemTime:outputItemTime];
    if (hasNewPixelBuffer) {
        CMTime outItemTimeForDisplay;
        CVPixelBufferRef pixelBuffer = [_playerItemVideoOutput copyPixelBufferForItemTime:outputItemTime
                                                                       itemTimeForDisplay:&outItemTimeForDisplay];
        if (pixelBuffer) {
            _lastFrameTime = [NSDate date].timeIntervalSince1970;
            if (!_framePool) {
                _framePool = [[KTVVPFramePool alloc] init];
            }
            KTVVPCVPixelBufferFrame *frame = [_framePool frameWithKey:[KTVVPCVPixelBufferFrame key] factory:^__kindof KTVVPFrame *{
                KTVVPCVPixelBufferFrame *result = [[KTVVPCVPixelBufferFrame alloc] init];
                return result;
            }];
            frame.pixelBuffer = pixelBuffer;
            frame.timeStamp = outItemTimeForDisplay;
            frame.hostTimeStamp = CMTimeMakeWithSeconds(CACurrentMediaTime(), 1000000);
            [self.pipeline inputFrame:frame fromSource:self];
            [frame unlock];
            CVPixelBufferRelease(pixelBuffer);
        }
    } else if ([NSDate date].timeIntervalSince1970 - _lastFrameTime > 5) {
        _displayLink.paused = YES;
        [_playerItemVideoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.03];
    }
}

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    _displayLink.paused = NO;
}

@end
