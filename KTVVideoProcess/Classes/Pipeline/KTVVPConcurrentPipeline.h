//
//  KTVVPConcurrentPipeline.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/26.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPipeline.h"

@interface KTVVPConcurrentPipeline : KTVVPPipeline

/**
 *  Default value is 3.
 */
@property (nonatomic, assign) NSInteger maxConcurrentCount;

/**
 *  Set this block to configuration the filter when the pipeline did create it.
 */
@property (nonatomic, copy) void (^filterConfigurationCallback)(__kindof KTVVPFilter *filter, NSInteger index, NSInteger serialPipelineIndex);

/**
 *  Filters for specify class.
 */
- (NSArray <__kindof KTVVPFilter *> *)filtersOfClass:(Class)queryClass;


@end
