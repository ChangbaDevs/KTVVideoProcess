//
//  KTVVPPixelBufferPool.m
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/4.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPixelBufferPool.h"
#import "KTVVPLog.h"

@interface KTVVPPixelBufferPool ()

@property (nonatomic, assign) CVPixelBufferPoolRef pixelBufferPool;

@end

@implementation KTVVPPixelBufferPool

- (void)dealloc
{
    if (_pixelBufferPool) {
        CVPixelBufferPoolRelease(_pixelBufferPool);
        _pixelBufferPool = NULL;
    }
}

- (CVPixelBufferRef)copyPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVReturn error;
    if (!_pixelBufferPool) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        [attributes setObject:@(CVPixelBufferGetPixelFormatType(pixelBuffer))
                       forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [attributes setObject:@(CVPixelBufferGetWidth(pixelBuffer))
                       forKey:(id)kCVPixelBufferWidthKey];
        [attributes setObject:@(CVPixelBufferGetHeight(pixelBuffer))
                       forKey:(id)kCVPixelBufferHeightKey];
        [attributes setObject:@(CVPixelBufferGetBytesPerRow(pixelBuffer))
                       forKey:(id)kCVPixelBufferBytesPerRowAlignmentKey];
        [attributes setObject:@{}
                       forKey:(id)kCVPixelBufferIOSurfacePropertiesKey];
        error = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef)attributes, &_pixelBufferPool);
        if (error != kCVReturnSuccess) {
            KTVVPLog(@"create CVPixelBufferPool failed");
        }
    }
    CVPixelBufferRef ret = NULL;
    error = CVPixelBufferPoolCreatePixelBuffer(NULL, _pixelBufferPool, &ret);
    if(error != kCVReturnSuccess) {
        KTVVPLog(@"create CVPixelBuffer failed");
    }
    CVPixelBufferLockBaseAddress(ret, 0);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t dataSize = CVPixelBufferGetDataSize(ret);
    size_t sourceDataSize = CVPixelBufferGetDataSize(pixelBuffer);
    void *dataPointer = CVPixelBufferGetBaseAddress(ret);
    void *sourceDataPointer = CVPixelBufferGetBaseAddress(pixelBuffer);
    memcpy(dataPointer, sourceDataPointer, MIN(dataSize, sourceDataSize));
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(ret, 0);
    return ret;
}

@end
