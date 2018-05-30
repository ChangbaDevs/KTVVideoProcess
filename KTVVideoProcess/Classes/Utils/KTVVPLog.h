//
//  KTVVPLog.h
//  KTVVideoProcess
//
//  Created by Single on 2018/5/30.
//  Copyright © 2018年 Single. All rights reserved.
//

#ifndef KTVVPLog_h
#define KTVVPLog_h

#import <Foundation/Foundation.h>

#define KTVVPLogEnable 0

#if KTVVPLogEnable
#define KTVVPLog(...) NSLog(__VA_ARGS__)
#else
#define KTVVPLog(...)
#endif

#endif /* KTVVPLog_h */
