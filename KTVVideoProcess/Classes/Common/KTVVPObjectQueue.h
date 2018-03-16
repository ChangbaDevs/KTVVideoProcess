//
//  KTVVPObjectQueue.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVVPObjectQueue : NSObject

- (void)putObject:(id)object;
- (id)getObjectSync;

- (void)destory;

@end
