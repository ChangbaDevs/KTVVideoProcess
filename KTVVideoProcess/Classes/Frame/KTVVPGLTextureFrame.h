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
@property (nonatomic, copy, readonly) void (^uploadTextureCallback)(KTVVPGLTextureFrame *frame);

/**
 *  Release the texture data in this callback.
 */
@property (nonatomic, copy, readonly) void (^releaseTextureCallback)(KTVVPGLTextureFrame *frame);

- (void)setUploadTextureCallback:(void (^)(KTVVPGLTextureFrame *frame))uploadTextureCallback
          releaseTextureCallback:(void (^)(KTVVPGLTextureFrame *frame))releaseTextureCallback;

@end
