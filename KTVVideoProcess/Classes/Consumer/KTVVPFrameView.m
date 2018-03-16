//
//  KTVVPFrameView.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPFrameView.h"
#import "KTVVPMessageLoop.h"
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
@property (nonatomic, strong) EAGLContext * glContext;
@property (nonatomic, strong) KTVVPGLRGBProgram * glProgram;
@property (nonatomic, strong) KTVVPGLPlaneModel * glModel;
@property (nonatomic, strong) KTVVPFrameUploader * frameUploader;
@property (nonatomic, strong) KTVVPMessageLoop * messageLoop;
@property (nonatomic, strong) dispatch_queue_t runningQueue;

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
            self.glScale = self.contentScaleFactor;
        }
        
        self.glLayer = (CAEAGLLayer *)self.layer;
        self.glLayer.opaque = YES;
        self.glLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @(NO),
                                            kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};
        
        self.runningQueue = dispatch_queue_create("KTVVPFrameView-running-queue", DISPATCH_QUEUE_SERIAL);
        self.messageLoop = [[KTVVPMessageLoop alloc] init];
        self.messageLoop.delegate = self;
        [self.messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLSetupContext object:nil]];
        [self.messageLoop run];
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
        [self.messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLSetupFramebuffer object:nil]];
    }
}

- (void)putFrame:(KTVVPFrame *)frame
{
    [frame lock];
    dispatch_async(self.runningQueue, ^{
        [self.messageLoop putMessage:[KTVVPMessage messageWithType:KTVVPMessageTypeOpenGLDrawing object:frame]];
    });
}

- (void)drawFrame:(KTVVPFrame *)frame
{
    [self drawPrepare];
    [self.glProgram use];
    [frame uploadIfNeed:self.frameUploader];
    [self.glProgram bindTexture:frame.texture];
    [self.glModel bindPosition_location:self.glProgram.position_location
             textureCoordinate_location:self.glProgram.textureCoordinate_location];
    [self.glModel draw];
    [self.glModel bindEmpty];
    [self drawFlush];
}

- (void)drawClear
{
    [self drawPrepare];
    [self drawFlush];
}

- (void)setCurrentGLContextIfNeed
{
    if ([EAGLContext currentContext] != self.glContext)
    {
        [EAGLContext setCurrentContext:self.glContext];
    }
}

- (void)drawPrepare
{
    [self setCurrentGLContextIfNeed];
    glBindFramebuffer(GL_FRAMEBUFFER, _glFramebuffer);
    glViewport(0, 0, (GLint)_displaySize.width * self.glScale, (GLint)_displaySize.height * self.glScale);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)drawFlush
{
    glBindRenderbuffer(GL_RENDERBUFFER, _glRenderbuffer);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}


#pragma mark - Setup

- (void)setupOpenGL
{
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                           sharegroup:self.context.mainGLContext.sharegroup];
    [self setCurrentGLContextIfNeed];
    self.glModel = [[KTVVPGLPlaneModel alloc] init];
    self.glProgram = [[KTVVPGLRGBProgram alloc] init];
    self.frameUploader = [[KTVVPFrameUploader alloc] initWithGLContext:self.glContext];
}

- (void)setupFramebuffer
{
    if (_displaySize.width == 0 || _displaySize.height == 0)
    {
        return;
    }
    [self setCurrentGLContextIfNeed];
    glGenFramebuffers(1, &_glFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _glFramebuffer);
    glGenRenderbuffers(1, &_glRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _glRenderbuffer);
    [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.glLayer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _glRenderbuffer);
}

- (void)destroyFramebuffer
{
    [self setCurrentGLContextIfNeed];
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
