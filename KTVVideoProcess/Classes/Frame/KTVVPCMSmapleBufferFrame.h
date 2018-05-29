//
//  KTVVPCMSmapleBufferFrame.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrame.h"

@interface KTVVPCMSmapleBufferFrame : KTVVPFrame

/**
 *  Containing data.
 */
@property (nonatomic, assign) CMSampleBufferRef sampleBuffer;

@end
