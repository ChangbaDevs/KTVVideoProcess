//
//  KTVVPMessageLoop.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPMessage.h"

@class KTVVPMessageLoop;

@protocol KTVVPMessageLoopDelegate <NSObject>

- (void)messageLoop:(KTVVPMessageLoop *)messageLoop processingMessage:(KTVVPMessage *)message;

@end

@interface KTVVPMessageLoop : NSObject

@property (nonatomic, weak) id <KTVVPMessageLoopDelegate> delegate;
@property (nonatomic, strong, readonly) NSThread * thread;

- (void)run;
- (void)stop;

- (void)putMessage:(KTVVPMessage *)message;

@end
