//
//  KTVVPPassthroughFilter.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFilter.h"
#import "KTVVPGLProgram.h"

/**
 *  Draw anyway
 */
@interface KTVVPPassthroughFilter : KTVVPFilter

/**
 *  Custom shader string, the shader format must comply with the standard program.
 *
 *  Default value is nil, if there is not set a vaild value, will use KTVVPGLStandardProgram‘s default shader string.
 */
@property (nonatomic, copy) NSString * vertexShaderString;
@property (nonatomic, copy) NSString * fragmentShaderString;

/**
 *  Override by subclass if needed.
 */
- (void)programCreated:(KTVVPGLProgram *)program;
- (void)programPrepare;
- (void)programDone;

@end
