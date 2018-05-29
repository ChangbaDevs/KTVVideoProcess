//
//  KTVVPPipeline.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/23.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPContext.h"
#import "KTVVPFilter.h"

@interface KTVVPPipeline : NSObject <KTVVPFrameInput>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithContext:(KTVVPContext *)context filterClasses:(NSArray <Class> *)filterClasses;

@property (nonatomic, strong, readonly) KTVVPContext * context;
@property (nonatomic, strong, readonly) NSArray <Class> * filterClasses;

/**
 *  Setup
 */
@property (nonatomic, assign, readonly) BOOL didSetup;
- (void)setupIfNeeded;

/**
 *  OpenGL
 *
 *  @property needFlushBeforOutput  Default value is YES.
 */
@property (nonatomic, assign) BOOL needFlushBeforOutput;
- (void)glFinish;

/**
 *  Block current thread until finished all operations.
 */
- (void)waitUntilFinished;

#pragma mark - Output

@property (nonatomic, strong, readonly) NSArray <id <KTVVPFrameInput>> * outputs;

- (void)addOutput:(id <KTVVPFrameInput>)output;
- (void)addOutputs:(NSArray <id <KTVVPFrameInput>> *)outputs;

- (void)removeOutput:(id <KTVVPFrameInput>)output;
- (void)removeOutputs:(NSArray <id <KTVVPFrameInput>> *)outputs;
- (void)removeAllOutputs;

@end
