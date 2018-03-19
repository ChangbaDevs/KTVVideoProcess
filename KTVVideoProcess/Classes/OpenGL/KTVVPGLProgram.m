//
//  KTVVPGLProgram.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLProgram.h"

@interface KTVVPGLProgram ()

{
    GLuint _program;
}

@property (nonatomic, assign) BOOL linkSuccess;

@end

@implementation KTVVPGLProgram

- (instancetype)initWithVertexShaderCString:(const char *)vertexShaderCString
                      fragmentShaderCString:(const char *)fragmentShaderCString
{
    return [self initWithVertexShaderString:[NSString stringWithCString:vertexShaderCString encoding:NSUTF8StringEncoding]
                       fragmentShaderString:[NSString stringWithCString:fragmentShaderCString encoding:NSUTF8StringEncoding]];
}

- (instancetype)initWithVertexShaderString:(NSString *)vertexShaderString
                      fragmentShaderString:(NSString *)fragmentShaderString
{
    if (self = [super init])
    {
        _vertexShaderString = vertexShaderString;
        _fragmentShaderString = fragmentShaderString;
        
        GLuint vertexShader;
        GLuint fragmentShader;
        BOOL vertexSuccess = [self compileShader:&vertexShader type:GL_VERTEX_SHADER string:vertexShaderString];
        BOOL fragmentSuccess = [self compileShader:&fragmentShader type:GL_FRAGMENT_SHADER string:fragmentShaderString];
        if (vertexSuccess && fragmentSuccess)
        {
            _program = glCreateProgram();
            glAttachShader(_program, vertexShader);
            glAttachShader(_program, fragmentShader);
            glLinkProgram(_program);
            GLint linkSuccess;
            glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
            _linkSuccess = linkSuccess == GL_TRUE;
        }
        if (vertexShader)
        {
            glDeleteShader(vertexShader);
        }
        if (fragmentShader)
        {
            glDeleteShader(fragmentShader);
        }
    }
    return self;
}

- (void)dealloc
{
    if (_program)
    {
        glDeleteProgram(_program);
    }
}

- (GLuint)attributeLocation:(NSString *)attributeName
{
    if (_program)
    {
        return glGetAttribLocation(_program, [attributeName UTF8String]);
    }
    return 0;
}

- (GLuint)uniformLocation:(NSString *)uniformName
{
    if (_program)
    {
        return glGetUniformLocation(_program, [uniformName UTF8String]);
    }
    return 0;
}

- (void)use
{
    if (_program)
    {
        glUseProgram(_program);
    }
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(NSString *)shaderString
{
    GLint status;
    const GLchar * source;
    
    source = (GLchar *)[shaderString UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load shader string");
        return NO;
    }
    
    * shader = glCreateShader(type);
    glShaderSource(* shader, 1, &source, NULL);
    glCompileShader(* shader);
    
    glGetShaderiv(* shader, GL_COMPILE_STATUS, &status);
    
    if (status != GL_TRUE)
    {
        GLint logLength;
        glGetShaderiv(* shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar * log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(* shader, logLength, &logLength, log);
            NSLog(@"Failed to compile shader : %s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

@end
