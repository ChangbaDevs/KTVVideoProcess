//
//  KTVVPFrameView.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTVVPContext.h"
#import "KTVVPFrameInput.h"

@interface KTVVPFrameView : UIView <KTVVPFrameInput>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithContext:(KTVVPContext *)context;

@property (nonatomic, strong, readonly) KTVVPContext * context;

@end
