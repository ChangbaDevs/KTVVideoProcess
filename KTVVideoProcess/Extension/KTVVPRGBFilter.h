//
//  KTVVPRGBFilter.h
//  KTVVideoProcess
//
//  Created by Single on 2018/5/29.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPassthroughFilter.h"

@interface KTVVPRGBFilter : KTVVPPassthroughFilter

/**
 *  Default value is 1.0.
 */
@property (nonatomic, assign) float red;
@property (nonatomic, assign) float green;
@property (nonatomic, assign) float blue;

@end
