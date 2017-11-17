//
//  Person.h
//  RuntimeTest
//
//  Created by UCS on 2017/11/16.
//  Copyright © 2017年 UCS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property(nonatomic ,assign) NSInteger weidht;

- (void) func1;
- (void) func2;
@end
