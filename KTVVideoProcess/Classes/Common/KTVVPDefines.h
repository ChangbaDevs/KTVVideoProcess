//
//  KTVVPDefines.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/21.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark - Enum

typedef NS_ENUM(NSUInteger, KTVVPRotationMode)
{
    KTVVPRotationMode0,
    KTVVPRotationMode90,
    KTVVPRotationMode180,
    KTVVPRotationMode270,
};

typedef NS_ENUM(NSUInteger, KTVVPFlipMode)
{
    KTVVPFlipModeNone,
    KTVVPFlipModeHorizonal,
    KTVVPFlipModeVertical,
    KTVVPFlipModeHorizonalAndVertical,
};

typedef NS_ENUM(NSUInteger, KTVVPScalingMode)
{
    KTVVPScalingModeResize,
    KTVVPScalingModeResizeAspect,
    KTVVPScalingModeResizeAspectFill,
};


#pragma mark - Struct

typedef struct KTVVPSize {
    int width;
    int height;
} KTVVPSize;

typedef struct KTVVPRect {
    int x;
    int y;
    int width;
    int height;
} KTVVPRect;


#pragma mark - Function

KTVVPSize KTVVPSizeZero(void);
KTVVPSize KTVVPSizeMake(int width, int height);
BOOL KTVVPSizeEqualToSize(KTVVPSize size1, KTVVPSize size2);

KTVVPRect KTVVPRectZero(void);
KTVVPRect KTVVPRectMake(int x, int y, int width, int height);
BOOL KTVVPRectEqualToRect(KTVVPRect rect1, KTVVPRect rect2);
