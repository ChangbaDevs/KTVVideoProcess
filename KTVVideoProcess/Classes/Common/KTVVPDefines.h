//
//  KTVVPDefines.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/21.
//  Copyright © 2018年 Single. All rights reserved.
//

#ifndef KTVVPDefines_h
#define KTVVPDefines_h


#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, KTVVPRotationMode)
{
    KTVVPRotationModeNone,
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


#endif /* KTVVPDefines_h */
