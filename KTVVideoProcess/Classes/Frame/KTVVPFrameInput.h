//
//  KTVVPFrameInput.h
//  KTVVideoProcess
//
//  Created by Single on 2018/3/26.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPFrame.h"

@protocol KTVVPFrameInput <NSObject>

- (BOOL)inputFrame:(KTVVPFrame *)frame fromSource:(id)source;

@end
