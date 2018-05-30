//
//  KTVVPPixelBufferPool.h
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/4.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface KTVVPPixelBufferPool : NSObject

/**
 *  Copy CVPixelBuffer, the input pixelBuffer must keep the same format.
 */
- (CVPixelBufferRef)copyPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
