//
//  KTVVPInput.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPFrame.h"

@protocol KTVVPInput <NSObject>

- (void)putFrame:(KTVVPFrame *)frame;

@end
