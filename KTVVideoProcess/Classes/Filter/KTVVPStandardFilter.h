//
//  KTVVPStandardFilter.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/9.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFilter.h"

@interface KTVVPStandardFilter : KTVVPFilter


#pragma mark - Override

- (NSString *)fragmentShaderString;

@end
