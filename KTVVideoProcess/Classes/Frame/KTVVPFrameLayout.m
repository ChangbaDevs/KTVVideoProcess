//
//  KTVVPFrameLayout.m
//  KTVVideoProcess
//
//  Created by Single on 2018/4/13.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameLayout.h"

@implementation KTVVPFrameLayout

- (id)copyWithZone:(NSZone *)zone
{
    KTVVPFrameLayout *obj = [[KTVVPFrameLayout alloc] init];
    obj.size = self.size;
    obj.rotationMode = self.rotationMode;
    obj.flipMode = self.flipMode;
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        _size = KTVVPSizeZero();
        _rotationMode = KTVVPRotationMode0;
        _flipMode = KTVVPFlipModeNone;
    }
    return self;
}

- (KTVVPSize)finalSize
{
    if (self.rotationQuarter) {
        return KTVVPSizeMake(_size.height, _size.width);
    }
    return _size;
}

- (KTVVPRotationMode)completionRotationMode
{
    if (_rotationMode == KTVVPRotationMode90) {
        return KTVVPRotationMode270;
    }
    if (_rotationMode == KTVVPRotationMode270) {
        return KTVVPRotationMode90;
    }
    return _rotationMode;
}

- (KTVVPFlipMode)textureFlipMode
{
    switch (_flipMode) {
        case KTVVPFlipModeNone:
            return KTVVPFlipModeVertical;
        case KTVVPFlipModeHorizonal:
            return KTVVPFlipModeHorizonalAndVertical;
        case KTVVPFlipModeVertical:
            return KTVVPFlipModeNone;
        case KTVVPFlipModeHorizonalAndVertical:
            return KTVVPFlipModeHorizonal;
    }
    return KTVVPFlipModeNone;
}

- (BOOL)rotationQuarter
{
    if (_rotationMode == KTVVPRotationMode90 || _rotationMode == KTVVPRotationMode270) {
        return YES;
    }
    return NO;
}

@end
