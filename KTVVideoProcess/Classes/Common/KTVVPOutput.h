//
//  KTVVPOutput.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPFrame.h"
#import "KTVVPInput.h"

@protocol KTVVPOutput <NSObject>

- (void)addInput:(id <KTVVPInput>)input;
- (void)removeInput:(id <KTVVPInput>)input;

- (void)outputFrame:(KTVVPFrame *)frame;

@end
