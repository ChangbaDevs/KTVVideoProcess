//
//  KTVVPGLTextureFrame.h
//  KTVShortVideoTest
//
//  Created by Single on 2018/4/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrame.h"

@interface KTVVPGLTextureFrame : KTVVPFrame

/**
 *  Upload the texture data in this callback.
 */
@property (nonatomic, copy) void (^uploadTextureCallback)(KTVVPGLTextureFrame * frame);

@end
