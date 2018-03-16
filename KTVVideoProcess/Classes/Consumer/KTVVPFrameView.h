//
//  KTVVPFrameView.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTVVPInput.h"
#import "KTVVPContext.h"

@interface KTVVPFrameView : UIView <KTVVPInput>

- (instancetype)initWithContext:(KTVVPContext *)context;

@property (nonatomic, strong, readonly) KTVVPContext * context;

@end
