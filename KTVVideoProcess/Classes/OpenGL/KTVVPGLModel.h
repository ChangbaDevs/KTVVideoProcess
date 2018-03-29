//
//  KTVVPGLModel.h
//  KTVVideoProcessDemo
//
//  Created by Single on 2018/3/15.
//  Copyright © 2018年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface KTVVPGLModel : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithGLContext:(EAGLContext *)glContext;

- (void)reloadData;

- (void)bindPosition_location:(GLint)position_location textureCoordinate_location:(GLint)textureCoordinate_location;
- (void)bindEmpty;
- (void)draw;


#pragma mark - Override

- (GLushort *)indexes_data;
- (GLfloat *)vertices_data;
- (GLfloat *)textureCoordinates_data;

- (int)indexes_count;
- (int)vertices_count;

@end
