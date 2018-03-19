//
//  KTVVPObjectQueue.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPObjectQueue.h"

@interface KTVVPObjectQueue ()

@property (nonatomic, strong) NSCondition * condition;
@property (nonatomic, strong) NSMutableArray * objects;
@property (nonatomic, assign) BOOL didDestoryed;

@end

@implementation KTVVPObjectQueue

- (instancetype)init
{
    if (self = [super init])
    {
        _condition = [[NSCondition alloc] init];
        _objects = [NSMutableArray array];
    }
    return self;
}

- (void)putObject:(id)object
{
    [_condition lock];
    [_objects addObject:object];
    [_condition signal];
    [_condition unlock];
}

- (id)getObjectSync
{
    [_condition lock];
    while (_objects.count <= 0)
    {
        [_condition wait];
        if (_didDestoryed)
        {
            [_condition unlock];
            return nil;
        }
    }
    id object = _objects.firstObject;
    [_objects removeObjectAtIndex:0];
    [_condition signal];
    [_condition unlock];
    return object;
}

- (void)destory
{
    _didDestoryed = YES;
}

@end
