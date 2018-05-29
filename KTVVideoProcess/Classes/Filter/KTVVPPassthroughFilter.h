//
//  KTVVPPassthroughFilter.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFilter.h"

/**
 *  Draw anyway
 */
@interface KTVVPPassthroughFilter : KTVVPFilter

/**
 *  Custom shader string. Default value is nil, if there is not set a vaild value, will use KTVVPGLStandardProgram‘s default shader string.
 */
@property (nonatomic, copy) NSString * vertexShaderString;
@property (nonatomic, copy) NSString * fragmentShaderString;

@end
