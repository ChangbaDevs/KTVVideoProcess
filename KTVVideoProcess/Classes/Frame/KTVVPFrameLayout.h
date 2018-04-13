//
//  KTVVPFrameLayout.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/13.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPDefines.h"

@interface KTVVPFrameLayout : NSObject <NSCopying>

@property (nonatomic, assign) KTVVPSize size;
@property (nonatomic, assign) KTVVPRotationMode rotationMode;
@property (nonatomic, assign) KTVVPFlipMode flipMode;
@property (nonatomic, assign, readonly) KTVVPSize finalSize;
@property (nonatomic, assign, readonly) KTVVPRotationMode completionRotationMode;
@property (nonatomic, assign, readonly) KTVVPFlipMode textureFlipMode;
@property (nonatomic, assign, readonly) BOOL rotationQuarter;

@end
