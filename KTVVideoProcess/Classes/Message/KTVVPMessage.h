//
//  KTVVPMessage.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KTVVPMessageTypeOpenGL)
{
    KTVVPMessageTypeOpenGLIdle,
    KTVVPMessageTypeOpenGLSetupContext,
    KTVVPMessageTypeOpenGLSetupFramebuffer,
    KTVVPMessageTypeOpenGLDrawing,
    KTVVPMessageTypeOpenGLClear,
};

@interface KTVVPMessage : NSObject

+ (instancetype)messageWithType:(NSUInteger)type object:(id)object;
+ (instancetype)messageWithType:(NSUInteger)type object:(id)object dropCallback:(void (^)(KTVVPMessage * message))dropCallback;

@property (nonatomic, assign) NSUInteger type;
@property (nonatomic, strong) id object;

@property (nonatomic, copy) void (^dropCallback)(KTVVPMessage * message);
- (void)drop;

@end
