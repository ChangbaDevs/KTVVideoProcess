//
//  KTVVPFramePrivate.h
//  KTVMediaKitDemo
//
//  Created by Single on 2018/5/28.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KTVVPFrameLockingDelegate <NSObject>

- (void)frameDidUnuse:(KTVVPFrame *)frame;

@end

@interface KTVVPFrame ()

@property (nonatomic, weak) id <KTVVPFrameLockingDelegate> lockingDelegate;

@property (nonatomic, assign) NSInteger lockingCount;

@end
