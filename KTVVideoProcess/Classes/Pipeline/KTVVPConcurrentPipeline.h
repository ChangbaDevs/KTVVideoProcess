//
//  KTVVPConcurrentPipeline.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/26.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPipeline.h"

@interface KTVVPConcurrentPipeline : KTVVPPipeline

@property (nonatomic, assign) NSInteger maxConcurrentCount;     // default is 3.

@end
