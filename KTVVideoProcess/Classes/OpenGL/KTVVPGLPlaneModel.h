//
//  KTVVPGLPlaneModel.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLModel.h"
#import "KTVVPDefines.h"

@interface KTVVPGLPlaneModel : KTVVPGLModel

@property (nonatomic, assign) KTVVPRotationMode rotationMode;
@property (nonatomic, assign) KTVVPFlipMode flipMode;

- (void)reloadDataIfNeeded;

@end
