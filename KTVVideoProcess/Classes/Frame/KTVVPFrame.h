//
//  KTVVPFrame.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPDefines.h"
#import "KTVVPFrameLayout.h"
#import "KTVVPFrameUploader.h"

/**
 *  Frame types.
 */
typedef NS_ENUM(NSUInteger, KTVVPFrameType)
{
    KTVVPFrameTypeUnknown,
    KTVVPFrameTypeGLTexture,
    KTVVPFrameTypeGLDrawable,
    KTVVPFrameTypeCVPixelBuffer,
    KTVVPFrameTypeCMSampleBuffer,
};

@interface KTVVPFrame : NSObject

- (KTVVPFrameType)type;

/**
 *  Basic information.
 */
@property (nonatomic, assign) CMTime timeStamp;
@property (nonatomic, assign) CMTime hostTimeStamp;
@property (nonatomic, strong) KTVVPFrameLayout * layout;

/**
 *  Filling Data.
 */
- (void)fillWithFrame:(KTVVPFrame *)frame;
- (void)fillWithFrameWithoutTransform:(KTVVPFrame *)frame;
- (void)clear;

/**
 *  Texture.
 */
@property (nonatomic, assign) GLuint texture;
@property (nonatomic, assign) KTVVPGLTextureOptions textureOptions;

/**
 *  Upload texture.
 */
@property (nonatomic, assign) BOOL didUpload;
@property (nonatomic, strong) KTVVPFrameUploader * uploader;
- (void)uploadIfNeeded:(KTVVPFrameUploader *)uploader;

/**
 *  Containing data.
 */
- (CVPixelBufferRef)corePixelBuffer;
@property (nonatomic, strong) AVDepthData * depthData NS_AVAILABLE_IOS(11_1);
@property (nonatomic, strong) id extendedObject;

/**
 *  Reuse Key.
 */
@property (nonatomic, copy) NSString * key;
+ (NSString *)key;
+ (NSString *)keyWithAppendString:(NSString *)string;

/**
 *  Locking.
 */
- (void)lock;
- (void)unlock;

@end
