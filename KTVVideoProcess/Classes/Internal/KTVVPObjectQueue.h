//
//  KTVVPObjectQueue.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTVVPObjectQueue : NSObject

/**
 * Put object.
 */
- (void)putObject:(id)object;

/**
 *  Get object.
 */
- (id)getObjectSync;
- (id)getObjectAsync;

/**
 *  Number of objects.
 */
- (NSInteger)count;

/**
 *  Stop receive new object and release all sync requests.
 */
- (void)stop;

/**
 *  Remove all objects.
 */
- (void)flush;

/**
 *  Remove all objects and stop receive new object.
 */
- (void)destory;

@end
