//
//  KTVVPPipeline.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPInput.h"
#import "KTVVPContext.h"

@interface KTVVPPipeline : NSObject

- (instancetype)initWithContext:(KTVVPContext *)context
                  filterClasses:(NSArray <Class> *)filterClasses;

@property (nonatomic, strong, readonly) KTVVPContext * context;
@property (nonatomic, strong, readonly) NSArray <Class> * filterClasses;

@property (nonatomic, assign, readonly) BOOL processing;
- (void)processFrame:(KTVVPFrame *)frame completionHandler:(void(^)(KTVVPFrame * frame))completionHandler;

- (void)setupIfNeed;

@end
