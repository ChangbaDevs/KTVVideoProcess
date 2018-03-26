//
//  KTVVPFilter.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPContext.h"
#import "KTVVPFrameInput.h"

@interface KTVVPFilter : NSObject <KTVVPFrameInput>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithContext:(KTVVPContext *)context;

@property (nonatomic, strong, readonly) KTVVPContext * context;

@property (nonatomic, strong) id <KTVVPFrameInput> output;

- (void)outputFrame:(KTVVPFrame *)frame;

@end
