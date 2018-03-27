//
//  KTVVPGLPlaneModel.m
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVVPGLPlaneModel.h"

@interface KTVVPGLPlaneModel ()

@property (nonatomic, assign) BOOL needReloadData;

@end

@implementation KTVVPGLPlaneModel

- (void)reloadDataIfNeeded
{
    if (_needReloadData)
    {
        [self reloadData];
        _needReloadData = NO;
    }
}

- (void)setRotationMode:(KTVVPRotationMode)rotationMode
{
    if (_rotationMode != rotationMode)
    {
        _rotationMode = rotationMode;
        _needReloadData = YES;
    }
}

- (void)setFlipMode:(KTVVPFlipMode)flipMode
{
    if (_flipMode != flipMode)
    {
        _flipMode = flipMode;
        _needReloadData = YES;
    }
}

- (GLushort *)indexes_data
{
    static GLushort indexes_data[] =
    {
        0, 1, 2,
        0, 2, 3,
    };
    return indexes_data;
}

- (GLfloat *)vertices_data
{
    static GLfloat vertices_data[] =
    {
        -1, -1, 0.0,
        1, -1, 0.0,
        1, 1, 0.0,
        -1, 1, 0.0,
    };
    return vertices_data;
}
- (GLfloat *)textureCoordinates_data
{
    static GLfloat textureCoordinates_data_r0_fn[] =
    {
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
    };
    static GLfloat textureCoordinates_data_r0_fh[] =
    {
        1.0, 0.0,
        0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
    };
    static GLfloat textureCoordinates_data_r0_fv[] =
    {
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,
    };
    static GLfloat textureCoordinates_data_r90_fn[] =
    {
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,
    };
    static GLfloat textureCoordinates_data_r90_fh[] =
    {
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,
        0.0, 1.0,
    };
    static GLfloat textureCoordinates_data_r90_fv[] =
    {
        0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
    };
    static GLfloat textureCoordinates_data_r180_fn[] =
    {
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
    };
    static GLfloat textureCoordinates_data_r180_fh[] =
    {
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,
    };
    static GLfloat textureCoordinates_data_r180_fv[] =
    {
        1.0, 0.0,
        0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
    };
    static GLfloat textureCoordinates_data_r270_fn[] =
    {
        0.0, 1.0,
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
    };
    static GLfloat textureCoordinates_data_r270_fh[] =
    {
        0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
    };
    static GLfloat textureCoordinates_data_r270_fv[] =
    {
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,
        0.0, 1.0,
    };
    switch (_rotationMode)
    {
        case KTVVPRotationModeNone:
        {
            switch (_flipMode)
            {
                case KTVVPFlipModeNone:
                    return textureCoordinates_data_r0_fn;
                case KTVVPFlipModeHorizonal:
                    return textureCoordinates_data_r0_fh;
                case KTVVPFlipModeVertical:
                    return textureCoordinates_data_r0_fv;
            }
        }
        case KTVVPRotationMode90:
        {
            switch (_flipMode)
            {
                case KTVVPFlipModeNone:
                    return textureCoordinates_data_r90_fn;
                case KTVVPFlipModeHorizonal:
                    return textureCoordinates_data_r90_fh;
                case KTVVPFlipModeVertical:
                    return textureCoordinates_data_r90_fv;
            }
        }
        case KTVVPRotationMode180:
        {
            switch (_flipMode)
            {
                case KTVVPFlipModeNone:
                    return textureCoordinates_data_r180_fn;
                case KTVVPFlipModeHorizonal:
                    return textureCoordinates_data_r180_fh;
                case KTVVPFlipModeVertical:
                    return textureCoordinates_data_r180_fv;
            }
        }
        case KTVVPRotationMode270:
        {
            switch (_flipMode)
            {
                case KTVVPFlipModeNone:
                    return textureCoordinates_data_r270_fn;
                case KTVVPFlipModeHorizonal:
                    return textureCoordinates_data_r270_fh;
                case KTVVPFlipModeVertical:
                    return textureCoordinates_data_r270_fv;
            }
        }
    }
    return textureCoordinates_data_r0_fn;
}

- (int)indexes_count
{
    return 6;
}

- (int)vertices_count
{
    return 4;
}

@end
