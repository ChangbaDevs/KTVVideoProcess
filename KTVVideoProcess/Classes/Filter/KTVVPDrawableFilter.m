//
//  KTVVPDrawableFilter.m
//  ktv
//
//  Created by Single on 2019/5/8.
//

#import "KTVVPDrawableFilter.h"
#import "KTVVPGLStandardProgram.h"
#import "KTVVPGLPlaneModel.h"
#import "KTVVPGLDrawableFrame.h"

@interface KTVVPDrawableFilter ()

@property (nonatomic, strong) KTVVPGLStandardProgram * glProgram;
@property (nonatomic, strong) KTVVPGLPlaneModel * glModel;

@end

@implementation KTVVPDrawableFilter

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
        _glProgram = [[KTVVPGLStandardProgram alloc] initWithGLContext:self.glContext];
    }
    [frame lock];
    KTVVPSize size = frame.layout.size;
    NSString * key = [KTVVPGLDrawableFrame keyWithAppendString:[NSString stringWithFormat:@"%d-%d", size.width, size.height]];
    KTVVPGLDrawableFrame * result = [self.framePool frameWithKey:key factory:^__kindof KTVVPFrame *{
        KTVVPGLDrawableFrame * obj = [[KTVVPGLDrawableFrame alloc] init];
        return obj;
    }];
    [result fillWithFrame:frame];
    [frame uploadIfNeeded:self.frameUploader];
    [result uploadIfNeeded:self.frameUploader];
    [result bindDrawable];
    [result fillColorBlack];
    [_glProgram use];
    [_glProgram bindTexture:frame.texture];
    [_glModel bindPosition_location:_glProgram.position_location
         textureCoordinate_location:_glProgram.textureCoordinate_location];
    [_glModel draw];
    [_glModel unbind];
    [_glProgram unbindTexture];
    [result unbindDrawable];
    [frame unlock];
    BOOL ret = [super inputFrame:result fromSource:source];
    [result unlock];
    return ret;
}

@end
