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

- (instancetype)initWithGLContext:(EAGLContext *)glContext
                        framePool:(KTVVPFramePool *)framePool
                    frameUploader:(KTVVPFrameUploader *)frameUploader
{
    if (self = [super initWithGLContext:glContext
                              framePool:framePool
                          frameUploader:frameUploader])
    {
        _directPass = NO;
        _handleTransform = YES;
        
        [self.glContext setCurrentIfNeeded];
        _glModel = [[KTVVPGLPlaneModel alloc] initWithGLContext:self.glContext];
        _glProgram = [[KTVVPGLRGBProgram alloc] initWithGLContext:self.glContext];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
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
    
    [self.glContext setCurrentIfNeeded];
    [frame lock];
    KTVVPGLSize size = frame.size;
    if (_handleTransform)
    {
        size = frame.finalSize;
    }
    NSString * key = [KTVVPFrameDrawable keyWithAppendString:[NSString stringWithFormat:@"%d-%d", size.width, size.height]];
    KTVVPFrameDrawable * result = [self.framePool frameWithKey:key factory:^__kindof KTVVPFrame *{
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
    [result uploadIfNeeded:self.frameUploader];
    [result bindFramebuffer];
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [_glProgram use];
    [frame uploadIfNeeded:self.frameUploader];
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
