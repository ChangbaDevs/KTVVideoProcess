//
//  KTVVPGLDefines.h
//  KTVVideoProcess
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef KTVVPGLDefines_h
#define KTVVPGLDefines_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "KTVVPGLUtils.h"

#define KTV_GLES_CSTRINGIZE(x) #x
#define KTV_GLES_STRINGIZE(x) @ KTV_GLES_CSTRINGIZE(x)

typedef struct KTVVPGLTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} KTVVPGLTextureOptions;

#endif /* KTVVPGLDefines_h */
