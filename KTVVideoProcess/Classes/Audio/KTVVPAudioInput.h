//
//  KTVVPAudioInput.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/4/27.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KTVVPAudioSampleBuffer.h"

@protocol KTVVPAudioInput <NSObject>

- (void)inputAudioSampleBuffer:(KTVVPAudioSampleBuffer *)audioSampleBuffer fromSource:(id)source;

@end

