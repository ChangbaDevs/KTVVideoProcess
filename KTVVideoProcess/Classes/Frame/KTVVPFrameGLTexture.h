//
//  KTVVPFrameGLTexture.h
//  KTVShortVideoTest
//
//  Created by Single on 2018/4/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrame.h"

@interface KTVVPFrameGLTexture : KTVVPFrame

@property (nonatomic, copy) void (^uploadTextureCallback)(KTVVPFrameGLTexture * frame);

@end
