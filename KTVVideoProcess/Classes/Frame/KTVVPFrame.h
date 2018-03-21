//
//  KTVVPFrame.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "KTVVPGLDefines.h"
#import "KTVVPFrameUploader.h"


typedef NS_ENUM(NSUInteger, KTVVPFrameType)
{
    KTVVPFrameTypeIdle,
    KTVVPFrameTypeTextureOnly,
    KTVVPFrameTypeDrawable,
    KTVVPFrameTypeCMSampleBuffer,
};

typedef NS_ENUM(NSUInteger, KTVVPFrameRotationMode)
{
    KTVVPFrameRotationModeNone,
    KTVVPFrameRotationMode90,
    KTVVPFrameRotationMode180,
    KTVVPFrameRotationMode270,
};

typedef NS_ENUM(NSUInteger, KTVVPFrameFlipMode)
{
    KTVVPFrameFlipModeNone,
    KTVVPFrameFlipModeHorizonal,
    KTVVPFrameFlipModeVertical,
};


@class KTVVPFrame;

@protocol KTVVPFrameLockingDelegate <NSObject>

- (void)frameDidUnuse:(KTVVPFrame *)frame;

@end


@interface KTVVPFrame : NSObject

- (KTVVPFrameType)type;

@property (nonatomic, assign) GLuint texture;
@property (nonatomic, assign) KTVVPGLTextureOptions textureOptions;
@property (nonatomic, assign) KTVVPGLSize size;
@property (nonatomic, assign) KTVVPFrameRotationMode rotationMode;
@property (nonatomic, assign) KTVVPFrameFlipMode flipMode;
@property (nonatomic, assign) BOOL didUpload;

- (void)fillWithFrame:(KTVVPFrame *)frame;
- (void)uploadIfNeed:(KTVVPFrameUploader *)uploader;
- (void)clear;


#pragma mark - Data

- (CVPixelBufferRef)corePixelBuffer;


#pragma mark - Reuse Key

@property (nonatomic, copy) NSString * key;
+ (NSString *)key;
+ (NSString *)keyWithAppendString:(NSString *)string;


#pragma mark - Locking

@property (nonatomic, weak) id <KTVVPFrameLockingDelegate> lockingDelegate;

- (void)lock;
- (void)unlock;

@end
