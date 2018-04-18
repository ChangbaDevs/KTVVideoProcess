//
//  KTVVPSource.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/23.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPPipeline.h"

@interface KTVVPSource : NSObject


#pragma mark - Control

@property (atomic, assign) BOOL paused;

- (void)prepare;
- (void)start;
- (void)stop;


#pragma mark - Output

@property (atomic, weak) KTVVPPipeline * pipeline;

@end
