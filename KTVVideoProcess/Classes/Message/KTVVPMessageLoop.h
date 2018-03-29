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

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithIdentify:(NSString *)identify;

@property (nonatomic, copy, readonly) NSString * identify;
@property (nonatomic, weak) id <KTVVPMessageLoopDelegate> delegate;
@property (nonatomic, strong, readonly) NSThread * thread;
@property (nonatomic, assign, readonly) BOOL running;

- (void)run;
- (void)stop;

- (void)putMessage:(KTVVPMessage *)message;
- (void)putMessage:(KTVVPMessage *)message delay:(NSTimeInterval)delay;


#pragma mark - Flow Control

@property (nonatomic, copy) void (^threadDidStartedCallback)(KTVVPMessageLoop * messageLoop);
@property (nonatomic, copy) void (^threadDidFiniahedCallback)(KTVVPMessageLoop * messageLoop);

- (void)waitUntilThreadDidFinished;

@end
