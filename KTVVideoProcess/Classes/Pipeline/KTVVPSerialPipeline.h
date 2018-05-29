//
//  KTVVPSerialPipeline.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/23.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPipeline.h"

@interface KTVVPSerialPipeline : KTVVPPipeline

/**
 *  processing
 */
@property (nonatomic, assign, readonly) BOOL processing;

/**
 *  Set this block to configuration the filter when the pipeline did create it.
 */
@property (nonatomic, copy) void (^filterConfigurationCallback)(__kindof KTVVPFilter * filter, NSInteger index);

/**
 *  Filters for specify class.
 */
- (NSArray <__kindof KTVVPFilter *> *)filtersOfClass:(Class)queryClass;


@end
