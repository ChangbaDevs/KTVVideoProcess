//
//  KTVVPMessage.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPMessage.h"

@implementation KTVVPMessage

+ (instancetype)messageWithType:(NSUInteger)type object:(id)object
{
    return [[self alloc] initWithType:type object:object dropCallback:nil];
}

+ (instancetype)messageWithType:(NSUInteger)type object:(id)object dropCallback:(void (^)(KTVVPMessage *))dropCallback
{
    return [[self alloc] initWithType:type object:object dropCallback:dropCallback];
}

- (instancetype)initWithType:(NSUInteger)type object:(id)object dropCallback:(void (^)(KTVVPMessage *))dropCallback
{
    if (self = [super init])
    {
        _type = type;
        _object = object;
        _dropCallback = dropCallback;
    }
    return self;
}

- (void)drop
{
    NSLog(@"%s", __func__);
    
    if (_dropCallback)
    {
        _dropCallback(self);
    }
}

@end
