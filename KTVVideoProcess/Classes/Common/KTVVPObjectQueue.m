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
@property (nonatomic, assign) BOOL disableSyncRequest;

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

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    [self destory];
}

- (void)putObject:(id)object
{
    if (_didDestoryed)
    {
        return;
    }
    [_condition lock];
    [_objects addObject:object];
    [_condition signal];
    [_condition unlock];
}

- (id)getObjectSync
{
    if (_didDestoryed)
    {
        return nil;
    }
    [_condition lock];
    while (_objects.count <= 0 && !_disableSyncRequest)
    {
        [_condition wait];
        if (_didDestoryed)
        {
            [_condition unlock];
            return nil;
        }
    }
    id object = _objects.firstObject;
    if (object)
    {
        [_objects removeObjectAtIndex:0];
    }
    [_condition unlock];
    return object;
}

- (id)getObjectAsync
{
    if (_didDestoryed)
    {
        return nil;
    }
    [_condition lock];
    id object = _objects.firstObject;
    if (object)
    {
        [_objects removeObjectAtIndex:0];
    }
    [_condition unlock];
    return object;
}

- (void)broadcastAllSyncRequest
{
    if (_didDestoryed)
    {
        return;
    }
    [_condition lock];
    _disableSyncRequest = YES;
    [_condition broadcast];
    [_condition unlock];
}

- (void)flush
{
    if (_didDestoryed)
    {
        return;
    }
    [_condition lock];
    [_objects removeAllObjects];
    [_condition broadcast];
    [_condition unlock];
}

- (void)destory
{
    if (_didDestoryed)
    {
        return;
    }
    _didDestoryed = YES;
    [self flush];
}

@end
