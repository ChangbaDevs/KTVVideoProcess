//
//  KTVVPPassThroughFilter.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPassThroughFilter.h"
#import "KTVVPGLRGBProgram.h"
#import "KTVVPGLPlaneModel.h"
#import "KTVVPFrameDrawable.h"

@interface KTVVPPassThroughFilter ()

@property (nonatomic, strong) KTVVPGLRGBProgram * glProgram;
@property (nonatomic, strong) KTVVPGLPlaneModel * glModel;

@end

@implementation KTVVPPassThroughFilter

- (instancetype)initWithContext:(KTVVPContext *)context
{
    if (self = [super initWithContext:context])
    {
        [self.context setGLContextForCurrentThreadIfNeeded];
        _glModel = [[KTVVPGLPlaneModel alloc] init];
        _glProgram = [[KTVVPGLRGBProgram alloc] init];
    }
    return self;
}

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    [self.context setGLContextForCurrentThreadIfNeeded];
    [frame lock];
    KTVVPFramePool * framePool = [self.context framePoolCurrentThread];
    NSString * key = [KTVVPFrameDrawable keyWithAppendString:[NSString stringWithFormat:@"%d-%d", frame.size.width, frame.size.height]];
    KTVVPFrameDrawable * result = [framePool frameWithKey:key factory:^__kindof KTVVPFrame *{
        KTVVPFrame * result = [[KTVVPFrameDrawable alloc] init];
        return result;
    }];
    [result fillWithFrame:frame];
    [result uploadIfNeeded:[self.context frameUploaderForCurrentThread]];
    [result bindFramebuffer];
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [_glProgram use];
    [frame uploadIfNeeded:[self.context frameUploaderForCurrentThread]];
    [_glProgram bindTexture:frame.texture];
    [_glModel bindPosition_location:_glProgram.position_location
         textureCoordinate_location:_glProgram.textureCoordinate_location];
    [_glModel draw];
    [_glModel bindEmpty];
    [frame unlock];
    [self outputFrame:result];
    [result unlock];
}

@end
