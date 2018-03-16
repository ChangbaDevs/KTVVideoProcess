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
    return [[self alloc] initWithType:type object:object];
}

- (instancetype)initWithType:(NSUInteger)type object:(id)object
{
    if (self = [super init])
    {
        self.type = type;
        self.object = object;
    }
    return self;
}

@end
