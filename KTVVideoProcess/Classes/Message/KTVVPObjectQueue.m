//
//  KTVVPObjectQueue.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPObjectQueue.h"
#import "KTVVPLog.h"

@interface KTVVPObjectQueue ()

@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, assign) BOOL didDestoryed;
@property (nonatomic, assign) BOOL didStoped;

@end

@implementation KTVVPObjectQueue

- (instancetype)init
{
    if (self = [super init]) {
        KTVVPLog(@"%p, %s", self, __func__);
        _condition = [[NSCondition alloc] init];
        _objects = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    KTVVPLog(@"%p, %s", self, __func__);
    [self destory];
}

- (void)putObject:(id)object
{
    [_condition lock];
    if (_didDestoryed || _didStoped) {
        [_condition unlock];
        return;
    }
    [_objects addObject:object];
    [_condition signal];
    [_condition unlock];
}

- (id)getObjectSync
{
    [_condition lock];
    if (_didDestoryed) {
        [_condition unlock];
        return nil;
    }
    while (_objects.count <= 0 && !_didStoped) {
        [_condition wait];
        if (_didDestoryed) {
            [_condition unlock];
            return nil;
        }
    }
    id object = _objects.firstObject;
    if (object) {
        [_objects removeObjectAtIndex:0];
    }
    [_condition unlock];
    return object;
}

- (id)getObjectAsync
{
    [_condition lock];
    if (_didDestoryed) {
        [_condition unlock];
        return nil;
    }
    id object = _objects.firstObject;
    if (object) {
        [_objects removeObjectAtIndex:0];
    }
    [_condition unlock];
    return object;
}

- (NSInteger)count
{
    [_condition lock];
    NSInteger count = _objects.count;
    [_condition unlock];
    return count;
}

- (void)stop
{
    [_condition lock];
    if (_didDestoryed) {
        [_condition unlock];
        return;
    }
    _didStoped = YES;
    [_condition broadcast];
    [_condition unlock];
}

- (void)flush
{
    [_condition lock];
    if (_didDestoryed) {
        [_condition unlock];
        return;
    }
    [_objects removeAllObjects];
    [_condition broadcast];
    [_condition unlock];
}

- (void)destory
{
    [_condition lock];
    if (_didDestoryed) {
        [_condition unlock];
        return;
    }
    _didDestoryed = YES;
    [_objects removeAllObjects];
    [_condition broadcast];
    [_condition unlock];
}

@end
