//
//  KTVVPCVPixelBufferFrame.h
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/3.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrame.h"

@interface KTVVPCVPixelBufferFrame : KTVVPFrame

/**
 *  Containing data
 */
@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

@end
