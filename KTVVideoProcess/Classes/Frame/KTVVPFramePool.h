//
//  KTVVPFramePool.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPFrame.h"

@interface KTVVPFramePool : NSObject

/**
 *  @param key      The key for reuse.
 *  @param factory  If the frame pool has no vaild frame, this block will be called.
 */
- (__kindof KTVVPFrame *)frameWithKey:(NSString *)key factory:(__kindof KTVVPFrame *(^)(void))factory;

@end
