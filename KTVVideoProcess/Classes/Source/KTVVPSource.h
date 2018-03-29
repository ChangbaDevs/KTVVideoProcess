//
//  KTVVPSource.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/23.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPContext.h"
#import "KTVVPPipeline.h"

@interface KTVVPSource : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithContext:(KTVVPContext *)context;

@property (nonatomic, strong, readonly) KTVVPContext * context;


#pragma mark - Control

@property (nonatomic, assign) BOOL paused;

- (void)start;
- (void)stop;


#pragma mark - Output

@property (nonatomic, weak) KTVVPPipeline * pipeline;

@end
