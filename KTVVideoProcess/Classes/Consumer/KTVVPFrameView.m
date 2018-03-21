//
//  KTVVPFrameView.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameView.h"
#import "KTVVPMessageLoop.h"
#import "KTVVPDefines.h"
#import "KTVVPGLDefines.h"
#import "KTVVPGLRGBProgram.h"
#import "KTVVPGLPlaneModel.h"
#import <GLKit/GLKit.h>

@interface KTVVPFrameView () <KTVVPMessageLoopDelegate>

{
    GLuint _glFramebuffer;
    GLuint _glRenderbuffer;
}

@property (nonatomic, assign) KTVVPGLSize displaySize;

@property (nonatomic, assign) CGFloat glScale;
@property (nonatomic, strong) CAEAGLLayer * glLayer;
@property (nonatomic, strong) KTVVPGLRGBProgram * glProgram;
@property (nonatomic, strong) KTVVPGLPlaneModel * glModel;
@property (nonatomic, strong) KTVVPMessageLoop * messageLoop;

@end

@implementation KTVVPFrameView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)initWithContext:(KTVVPContext *)context
{
    if (self = [super initWithFrame:CGRectZero])
    {
        _context = context;
        
        if ([self respondsToSelector:@selector(setContentScaleFactor:)])
        {
            self.contentScaleFactor = [[UIScreen mainScreen] scale];
            _glScale = self.contentScaleFactor;
        }
        
        _glLayer = (CAEAGLLayer *)self.layer;
        _glLayer.opaque = YES;
        _glLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @(NO),
                                            kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
        
        _messageLoop = [[KTVVPMessageLoop alloc] init];
        _messageLoop.delegate = self;
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLSetupContext object:nil]];
        [_messageLoop run];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    int width = CGRectGetWidth(self.bounds);
    int height = CGRectGetHeight(self.bounds);
    if (width != _displaySize.width || height != _displaySize.width)
    {
        KTVVPGLSize displaySize = {width, height};
        _displaySize = displaySize;
        [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLSetupFramebuffer object:nil]];
    }
}

- (void)putFrame:(KTVVPFrame *)frame
{
    [frame lock];
    [_messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLDrawing object:frame]];
}

- (void)drawFrame:(KTVVPFrame *)frame
{
    [self drawPrepare];
    [_glProgram use];
    [frame uploadIfNeed:[_context currentFrameUploader]];
    [_glProgram bindTexture:frame.texture];
    _glModel.rotationMode = frame.rotationMode;
    _glModel.flipMode = frame.flipMode;
    [_glModel reloadDataIfNeed];
    [_glModel bindPosition_location:_glProgram.position_location
             textureCoordinate_location:_glProgram.textureCoordinate_location];
    [_glModel draw];
    [_glModel bindEmpty];
    [self drawFlush];
    [frame unlock];
}

- (void)drawClear
{
    [self drawPrepare];
    [self drawFlush];
}

- (void)drawPrepare
{
    [_context setCurrentGLContextIfNeed];
    glBindFramebuffer(GL_FRAMEBUFFER, _glFramebuffer);
    glViewport(0, 0, (GLint)_displaySize.width * self.glScale, (GLint)_displaySize.height * self.glScale);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)drawFlush
{
    glBindRenderbuffer(GL_RENDERBUFFER, _glRenderbuffer);
    [[_context currentGLContext] presentRenderbuffer:GL_RENDERBUFFER];
}


#pragma mark - Setup

- (void)setupOpenGL
{
    [_context setCurrentGLContextIfNeed];
    _glModel = [[KTVVPGLPlaneModel alloc] init];
    _glProgram = [[KTVVPGLRGBProgram alloc] init];
}

- (void)setupFramebuffer
{
    if (_displaySize.width == 0 || _displaySize.height == 0)
    {
        return;
    }
    [_context setCurrentGLContextIfNeed];
    glGenFramebuffers(1, &_glFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _glFramebuffer);
    glGenRenderbuffers(1, &_glRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _glRenderbuffer);
    [[_context currentGLContext] renderbufferStorage:GL_RENDERBUFFER fromDrawable:_glLayer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _glRenderbuffer);
}

- (void)destroyFramebuffer
{
    [_context setCurrentGLContextIfNeed];
    if (_glFramebuffer)
    {
        glDeleteFramebuffers(1, &_glFramebuffer);
        _glFramebuffer = 0;
    }
    if (_glRenderbuffer)
    {
        glDeleteRenderbuffers(1, &_glRenderbuffer);
        _glRenderbuffer = 0;
    }
}


#pragma mark - KTVVPMessageLoopDelegate

- (void)messageLoop:(KTVVPMessageLoop *)messageLoop processingMessage:(KTVVPMessage *)message
{
    if (message.type == KTVVPMessageTypeOpenGLSetupContext)
    {
        [self setupOpenGL];
    }
    else if (message.type == KTVVPMessageTypeOpenGLSetupFramebuffer)
    {
        [self destroyFramebuffer];
        [self setupFramebuffer];
    }
    else if (message.type == KTVVPMessageTypeOpenGLDrawing)
    {
        [self drawFrame:(KTVVPFrame *)message.object];
    }
    else if (message.type == KTVVPMessageTypeOpenGLClear)
    {
        [self drawClear];
    }
}

@end
