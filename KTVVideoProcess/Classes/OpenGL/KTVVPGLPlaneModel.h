//
//  KTVVPGLPlaneModel.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLModel.h"
#import "KTVVPDefines.h"

@interface KTVVPGLPlaneModel : KTVVPGLModel

/**
 *  Take effect after call reloadDataIfNeeded.
 */
@property (nonatomic, assign) KTVVPRotationMode rotationMode;
@property (nonatomic, assign) KTVVPFlipMode flipMode;

/**
 *  Reload data if rotationMode or flipModel did changed.
 */
- (void)reloadDataIfNeeded;

@end
