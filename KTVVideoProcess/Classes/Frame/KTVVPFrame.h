//
//  KTVVPFrame.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "KTVVPGLDefines.h"
#import "KTVVPFrameUploader.h"


typedef NS_ENUM(NSUInteger, KTVVPFrameType)
{
    KTVVPFrameTypeTextureRef,
    KTVVPFrameTypeTextureOnly,
    KTVVPFrameTypeDrawable,
    KTVVPFrameTypeCMSampleBuffer,
    KTVVPFrameTypeCVPixelBuffer,
};


@class KTVVPFrame;

@protocol KTVVPFrameDelegate <NSObject>

- (void)frameDidUnuse:(KTVVPFrame *)frame;

@end


@interface KTVVPFrame : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTextureRef:(GLuint)texture;

- (instancetype)initWithTextureOptions:(KTVVPGLTextureOptions)textureOptions;

- (instancetype)initWithFramebufferSize:(KTVVPGLSize)framebufferSize;
- (instancetype)initWithFramebufferSize:(KTVVPGLSize)framebufferSize
                         textureOptions:(KTVVPGLTextureOptions)textureOptions;

- (instancetype)initWithCMSmapleBuffer:(CMSampleBufferRef)sampleBuffer;
- (instancetype)initWithCMSmapleBuffer:(CMSampleBufferRef)sampleBuffer
                        textureOptions:(KTVVPGLTextureOptions)textureOptions;

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
                        textureOptions:(KTVVPGLTextureOptions)textureOptions;

@property (nonatomic, weak) id <KTVVPFrameDelegate> delegate;

@property (nonatomic, assign, readonly) KTVVPFrameType type;
@property (nonatomic, assign, readonly) GLuint texture;
@property (nonatomic, assign, readonly) KTVVPGLTextureOptions textureOptions;
@property (nonatomic, assign, readonly) KTVVPGLSize framebufferSize;
@property (nonatomic, assign, readonly) CMSampleBufferRef sampleBuffer;
@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

- (void)uploadIfNeed:(KTVVPFrameUploader *)uploader;
- (BOOL)didUpload;

- (void)bindFramebuffer;

- (void)lock;
- (void)unlock;

@end
