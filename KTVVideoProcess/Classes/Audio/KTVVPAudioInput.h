//
//  KTVVPAudioInput.h
//  KTVVideoProcess
//
//  Created by Single on 2018/4/27.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPSample.h"

@protocol KTVVPAudioInput <NSObject>

- (BOOL)inputSample:(KTVVPSample *)sample fromSource:(id)source;

@end

