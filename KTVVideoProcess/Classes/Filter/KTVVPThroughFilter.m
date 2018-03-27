//
//  KTVVPThroughFilter.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPThroughFilter.h"
#import "KTVVPGLRGBProgram.h"
#import "KTVVPGLPlaneModel.h"
#import "KTVVPFrameDrawable.h"

@interface KTVVPThroughFilter ()

@property (nonatomic, strong) KTVVPGLRGBProgram * glProgram;
@property (nonatomic, strong) KTVVPGLPlaneModel * glModel;

@end

@implementation KTVVPThroughFilter

- (instancetype)initWithContext:(KTVVPContext *)context
{
    if (self = [super initWithContext:context])
    {
        _directPass = NO;
        _handleTransform = YES;
    }
    return self;
}

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (!self.enable)
    {
        [super inputFrame:frame fromSource:source];
        return;
    }
    if (_directPass)
    {
        [super inputFrame:frame fromSource:source];
        return;
    }
    
    [self.context setGLContextForCurrentThreadIfNeeded];
    if (!_glModel)
    {
        _glModel = [[KTVVPGLPlaneModel alloc] init];
    }
    if (!_glProgram)
    {
        _glProgram = [[KTVVPGLRGBProgram alloc] init];
    }
    
    [frame lock];
    KTVVPFramePool * framePool = [self.context framePoolCurrentThread];
    KTVVPGLSize size = frame.size;
    if (_handleTransform)
    {
        size = frame.finalSize;
    }
    NSString * key = [KTVVPFrameDrawable keyWithAppendString:[NSString stringWithFormat:@"%d-%d", size.width, size.height]];
    KTVVPFrameDrawable * result = [framePool frameWithKey:key factory:^__kindof KTVVPFrame *{
        KTVVPFrame * result = [[KTVVPFrameDrawable alloc] init];
        return result;
    }];
    if (_handleTransform)
    {
        [result fillWithoutTransformWithFrame:frame];
        _glModel.rotationMode = frame.rotationMode;
        _glModel.flipMode = frame.flipMode;
    }
    else
    {
        [result fillWithFrame:frame];
        _glModel.rotationMode = KTVVPRotationModeNone;
        _glModel.flipMode = KTVVPFlipModeNone;
    }
    [_glModel reloadDataIfNeeded];
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
