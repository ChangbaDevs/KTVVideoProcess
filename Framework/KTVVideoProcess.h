//
//  KTVVideoProcess.h
//  KTVVideoProcess
//
//  Created by Single on 2018/5/29.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT double KTVVideoProcessVersionNumber;
FOUNDATION_EXPORT const unsigned char KTVVideoProcessVersionString[];

#pragma mark - Common

#import <KTVVideoProcess/KTVVPContext.h>
#import <KTVVideoProcess/KTVVPDefines.h>

#pragma mark - Source

#import <KTVVideoProcess/KTVVPSource.h>
#import <KTVVideoProcess/KTVVPCaptureSession.h>
#import <KTVVideoProcess/KTVVPAVPlayerItemVideoOutput.h>

#pragma mark - Pipeline

#import <KTVVideoProcess/KTVVPPipeline.h>
#import <KTVVideoProcess/KTVVPSerialPipeline.h>
#import <KTVVideoProcess/KTVVPConcurrentPipeline.h>

#pragma mark - Basic Filter

#import <KTVVideoProcess/KTVVPFilter.h>
#import <KTVVideoProcess/KTVVPTransformFilter.h>
#import <KTVVideoProcess/KTVVPPassthroughFilter.h>

#pragma mark - Output

#import <KTVVideoProcess/KTVVPFrameView.h>
#import <KTVVideoProcess/KTVVPFrameWriter.h>

#pragma mark - Frame

#import <KTVVideoProcess/KTVVPFrameInput.h>
#import <KTVVideoProcess/KTVVPFrame.h>
#import <KTVVideoProcess/KTVVPFramePool.h>
#import <KTVVideoProcess/KTVVPFrameLayout.h>
#import <KTVVideoProcess/KTVVPFrameUploader.h>
#import <KTVVideoProcess/KTVVPGLTextureFrame.h>
#import <KTVVideoProcess/KTVVPGLDrawableFrame.h>
#import <KTVVideoProcess/KTVVPCVPixelBufferFrame.h>
#import <KTVVideoProcess/KTVVPCMSmapleBufferFrame.h>

#pragma mark - Sample

#import <KTVVideoProcess/KTVVPSampleInput.h>
#import <KTVVideoProcess/KTVVPSample.h>

#pragma mark - OpenGL

#import <KTVVideoProcess/KTVVPGLDefines.h>
#import <KTVVideoProcess/KTVVPGLModel.h>
#import <KTVVideoProcess/KTVVPGLPlaneModel.h>
#import <KTVVideoProcess/KTVVPGLProgram.h>
#import <KTVVideoProcess/KTVVPGLStandardProgram.h>
#import <KTVVideoProcess/KTVVPGLImageTexture.h>
#import <KTVVideoProcess/KTVVPGLUtils.h>

#pragma mark - Export

#import <KTVVideoProcess/KTVVPExportSession.h>
#import <KTVVideoProcess/KTVVPExportReader.h>
#import <KTVVideoProcess/KTVVPExportWriter.h>

#pragma mark - Extension

#import <KTVVideoProcess/KTVVPRGBFilter.h>
#import <KTVVideoProcess/KTVVPExposureFilter.h>
#import <KTVVideoProcess/KTVVPBrightnessFilter.h>
#import <KTVVideoProcess/KTVVPBlackAndWhiteFilter.h>
