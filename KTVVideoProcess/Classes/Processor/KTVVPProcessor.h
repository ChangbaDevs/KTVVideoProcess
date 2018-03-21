//
//  KTVVPProcessor.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPInput.h"
#import "KTVVPOutput.h"
#import "KTVVPContext.h"

@interface KTVVPProcessor : NSObject <KTVVPInput, KTVVPOutput>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithContext:(KTVVPContext *)context
                  filterClasses:(NSArray <Class> *)filterClasses;

@property (nonatomic, strong, readonly) KTVVPContext * context;
@property (nonatomic, strong, readonly) NSArray <Class> * filterClasses;

@property (nonatomic, assign) BOOL needFlushBeforOutput;                // default is YES.
@property (nonatomic, assign) NSInteger maxConcurrentPipelineCount;     // default is 3.

- (void)setupIfNeed;

@end
