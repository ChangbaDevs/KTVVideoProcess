//
//  KTVVPExposureFilter.h
//  KTVVideoProcess
//
//  Created by Single on 2018/5/29.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPassthroughFilter.h"

@interface KTVVPExposureFilter : KTVVPPassthroughFilter

/**
 *  Default value is 0.0.
 */
@property (nonatomic, assign) float exposure;

@end
