//
//  KTVVPFrameCMSmapleBuffer.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrame.h"

@interface KTVVPFrameCMSmapleBuffer : KTVVPFrame

@property (nonatomic, assign) CMSampleBufferRef sampleBuffer;

@end
