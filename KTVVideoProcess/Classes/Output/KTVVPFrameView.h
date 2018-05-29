//
//  KTVVPFrameView.h
//  KTVVideoProcess
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

/**
 *  Default value is KTVVPScalingModeResizeAspect.
 */
@property (atomic, assign) KTVVPScalingMode scalingMode;

/**
 *  Determine when the frame timeStamp less than previous whether to display. Default value is YES.
 */
@property (atomic, assign) BOOL forwardOnly;

/**
 *  Asynchronization.
 */
- (void)snapshot:(void (^)(UIImage * image))callback;

/**
 *  Block current thread until finished all operations.
 */
- (void)waitUntilFinished;

@end
