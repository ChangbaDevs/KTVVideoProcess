//
//  KTVVPPassthroughFilter.m
//  KTVVideoProcess
//
//  Created by Single on 2018/3/19.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPPassthroughFilter.h"
#import "KTVVPGLStandardProgram.h"
#import "KTVVPGLPlaneModel.h"
#import "KTVVPGLDrawableFrame.h"

@interface KTVVPPassthroughFilter ()

@property (nonatomic, strong) KTVVPGLStandardProgram * glProgram;
@property (nonatomic, strong) KTVVPGLPlaneModel * glModel;

@end

@implementation KTVVPPassthroughFilter

- (void)programCreated:(KTVVPGLProgram *)program {}
- (void)programPrepare {}
- (void)programDone {}

#pragma mark - KTVVPFrameInput

- (BOOL)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    if (!self.enable)
    {
        return [super inputFrame:frame fromSource:source];
    }
    
    KTVVPSetCurrentGLContextIfNeeded(self.glContext);
    if (!_glModel)
    {
        _glModel = [[KTVVPGLPlaneModel alloc] initWithGLContext:self.glContext];
    }
    if (!_glProgram)
    {
        _glProgram = [[KTVVPGLStandardProgram alloc] initWithGLContext:self.glContext vertexShaderString:self.vertexShaderString fragmentShaderString:self.fragmentShaderString];
        [self programCreated:_glProgram.program];
    }
    [frame lock];
    KTVVPSize size = frame.layout.finalSize;
    NSString * key = [KTVVPGLDrawableFrame keyWithAppendString:[NSString stringWithFormat:@"%d-%d", size.width, size.height]];
    KTVVPGLDrawableFrame * result = [self.framePool frameWithKey:key factory:^__kindof KTVVPFrame *{
        KTVVPGLDrawableFrame * obj = [[KTVVPGLDrawableFrame alloc] init];
        return obj;
    }];
    [result fillWithFrameWithoutTransform:frame];
    [frame uploadIfNeeded:self.frameUploader];
    [result uploadIfNeeded:self.frameUploader];
    [result bindDrawable];
    [result fillColorBlack];
    [_glProgram use];
    [_glProgram bindTexture:frame.texture];
    [self programPrepare];
    _glModel.rotationMode = frame.layout.rotationMode;
    _glModel.flipMode = frame.layout.flipMode;
    [_glModel reloadDataIfNeeded];
    [_glModel bindPosition_location:_glProgram.position_location
             textureCoordinate_location:_glProgram.textureCoordinate_location];
    [_glModel draw];
    [_glModel unbind];
    [self programDone];
    [_glProgram unbindTexture];
    [result unbindDrawable];
    [frame unlock];
    BOOL ret = [super inputFrame:result fromSource:source];
    [result unlock];
    return ret;
}

@end
