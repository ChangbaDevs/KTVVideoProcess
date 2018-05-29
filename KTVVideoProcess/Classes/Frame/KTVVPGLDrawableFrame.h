//
//  KTVVPGLDrawableFrame.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrame.h"

@interface KTVVPGLDrawableFrame : KTVVPFrame

/**
 *  Bind/Unbind frameBuffer.
 */
- (void)bindDrawable;
- (void)unbindDrawable;

/**
 *  Clear color.
 */
- (void)fillColorBlack;
- (void)fillColorWithRed:(float)red green:(float)green blue:(float)blue alpha:(float)alpha;

@end
