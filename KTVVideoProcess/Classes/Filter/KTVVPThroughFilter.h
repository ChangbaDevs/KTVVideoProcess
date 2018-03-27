//
//  KTVVPThroughFilter.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFilter.h"

@interface KTVVPThroughFilter : KTVVPFilter

@property (nonatomic, assign) BOOL directPass;          // default is NO.
@property (nonatomic, assign) BOOL handleTransform;     // default is YES.

@end
