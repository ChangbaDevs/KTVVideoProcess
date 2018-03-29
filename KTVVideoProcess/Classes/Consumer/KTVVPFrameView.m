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
#import "EAGLContext+KTVVPExtension.h"

@interface KTVVPFrameView () <KTVVPMessageLoopDelegate>

{
    GLuint _glFramebuffer;
    GLuint _glRenderbuffer;
}

@property (nonatomic, assign) KTVVPGLSize displaySize;

@property (nonatomic, assign) CGFloat glScale;
@property (nonatomic, strong) CAEAGLLayer * glLayer;
@property (nonatomic, strong) EAGLContext * glContext;
@property (nonatomic, strong) KTVVPGLRGBProgram * glProgram;
@property (nonatomic, strong) KTVVPGLPlaneModel * glModel;
@property (nonatomic, strong) KTVVPFrameUploader * frameUploader;
@property (nonatomic, strong) KTVVPMessageLoop * messageLoop;
@property (nonatomic, assign) CMTime previousFrameTime;

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

- (void)dealloc
{
    NSLog(@"%s", __func__);
    
    [self destroyOnMessageLoopThread];
    [_messageLoop stop];
    _messageLoop = nil;
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


#pragma mark - Input

- (void)inputFrame:(KTVVPFrame *)frame fromSource:(id)source
{
    [frame lock];
    KTVVPMessage * message = [KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLDrawing object:frame];
    [message setDropCallback:^(KTVVPMessage * message) {
        KTVVPFrame * object = (KTVVPFrame *)message.object;
        [object unlock];
    }];
    [_messageLoop putMessage:message];
}


#pragma mark - OpenGL

- (void)drawFrame:(KTVVPFrame *)frame
{
    [self drawPrepare];
    [_glProgram use];
    [frame uploadIfNeeded:_frameUploader];
    [_glProgram bindTexture:frame.texture];
    _glModel.rotationMode = frame.rotationMode;
    _glModel.flipMode = frame.textureFlipMode;
    [_glModel reloadDataIfNeeded];
    [_glModel bindPosition_location:_glProgram.position_location
             textureCoordinate_location:_glProgram.textureCoordinate_location];
    [_glModel draw];
    [_glModel bindEmpty];
    [self drawFlush];
}

- (void)drawClear
{
    [self drawPrepare];
    [self drawFlush];
}

- (void)drawPrepare
{
    [_glContext setCurrentIfNeeded];
    glBindFramebuffer(GL_FRAMEBUFFER, _glFramebuffer);
    glViewport(0, 0, (GLint)_displaySize.width * self.glScale, (GLint)_displaySize.height * self.glScale);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)drawFlush
{
    glBindRenderbuffer(GL_RENDERBUFFER, _glRenderbuffer);
    [_glContext presentRenderbuffer:GL_RENDERBUFFER];
}


#pragma mark - Setup

- (void)setupOpenGL
{
    _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_context.mainGLContext.sharegroup];
    [_glContext setCurrentIfNeeded];
    _glModel = [[KTVVPGLPlaneModel alloc] initWithGLContext:_glContext];
    _glProgram = [[KTVVPGLRGBProgram alloc] initWithGLContext:_glContext];
    _frameUploader = [[KTVVPFrameUploader alloc] initWithGLContext:_glContext];
}

- (void)setupFramebuffer
{
    if (_displaySize.width == 0 || _displaySize.height == 0)
    {
        return;
    }
    [_glContext setCurrentIfNeeded];
    glGenFramebuffers(1, &_glFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _glFramebuffer);
    glGenRenderbuffers(1, &_glRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _glRenderbuffer);
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_glLayer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _glRenderbuffer);
}

- (void)destroyFramebuffer
{
    [_glContext setCurrentIfNeeded];
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

- (void)destroyOnMessageLoopThread
{
    EAGLContext * glContext = _glContext;
    GLuint glFramebuffer = _glFramebuffer;
    GLuint glRenderbuffer = _glRenderbuffer;
    [_messageLoop setThreadDidFiniahedCallback:^(KTVVPMessageLoop * messageLoop) {
        [glContext setCurrentIfNeeded];
        if (glFramebuffer)
        {
            glDeleteFramebuffers(1, &glFramebuffer);
        }
        if (glRenderbuffer)
        {
            glDeleteRenderbuffers(1, &glRenderbuffer);
        }
    }];
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
        KTVVPFrame * frame = (KTVVPFrame *)message.object;
        if (CMTIME_IS_VALID(frame.timeStamp)
            && CMTIME_IS_VALID(_previousFrameTime))
        {
            if (CMTimeCompare(frame.timeStamp, _previousFrameTime) < 0)
            {
                NSLog(@"KTVVPFrameView Frame time is less than previous time.");
                [frame unlock];
                return;
            }
        }
        _previousFrameTime = frame.timeStamp;
        [self drawFrame:frame];
        [frame unlock];
    }
    else if (message.type == KTVVPMessageTypeOpenGLClear)
    {
        [self drawClear];
    }
}

@end
