//
//  KTVVPPipeline.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/23.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPFrameInput.h"
#import "KTVVPContext.h"
#import "KTVVPFilter.h"

@interface KTVVPPipeline : NSObject <KTVVPFrameInput>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithContext:(KTVVPContext *)context
                  filterClasses:(NSArray <Class> *)filterClasses;

@property (nonatomic, strong, readonly) KTVVPContext * context;
@property (nonatomic, strong, readonly) NSArray <Class> * filterClasses;

@property (nonatomic, copy) void (^filterConfigurationCallback)(__kindof KTVVPFilter * filter, NSInteger filterIndexInPipiline, NSInteger pipelineIndex);
@property (nonatomic, assign) BOOL needFlushBeforOutput;        // default is YES.


#pragma mark - Setup

@property (nonatomic, assign, readonly) BOOL didSetup;
- (void)setupIfNeeded;


#pragma mark - Output

@property (nonatomic, strong, readonly) NSArray <id <KTVVPFrameInput>> * outputs;

- (void)addOutput:(id <KTVVPFrameInput>)output;
- (void)addOutputs:(NSArray <id <KTVVPFrameInput>> *)outputs;

- (void)removeOutput:(id <KTVVPFrameInput>)output;
- (void)removeOutputs:(NSArray <id <KTVVPFrameInput>> *)outputs;
- (void)removeAllOutputs;

- (void)outputFrame:(KTVVPFrame *)frame;

@end
