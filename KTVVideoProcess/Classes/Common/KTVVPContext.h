//
//  KTVVPContext.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/16.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

/**
 *  If the context is not create by sharedContext, Pay attention to that can't be share data between different context.
 */
@interface KTVVPContext : NSObject

/**
 *  The global context.
 */
+ (instancetype)sharedContext;

/**
 *  Provide sharegroup.
 */
@property (nonatomic, strong, readonly) EAGLContext * mainGLContext;

@end
