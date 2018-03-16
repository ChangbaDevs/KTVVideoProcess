//
//  KTVVPGLDefines.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef KTVVPGLDefines_h
#define KTVVPGLDefines_h


#import <Foundation/Foundation.h>


typedef struct KTVVPGLSize {
    int width;
    int height;
} KTVVPGLSize;

typedef struct KTVVPGLRect {
    int x;
    int y;
    int width;
    int height;
} KTVVPGLRect;

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
