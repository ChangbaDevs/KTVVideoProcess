//
//  KTVVPSource.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/23.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPPipeline.h"

@interface KTVVPSource : NSObject

#pragma mark - Trigger

@property (atomic, assign) BOOL paused;

- (void)prepare;
- (void)start;
- (void)stop;

#pragma mark - Output

@property (atomic, strong) KTVVPPipeline *pipeline;

@end
