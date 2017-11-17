//
//  Person.m
//  RuntimeTest
//
//  Created by UCS on 2017/11/16.
//  Copyright © 2017年 UCS. All rights reserved.
//

#import "Person.h"
#import <objc/objc-runtime.h>

@implementation Person

@dynamic weidht;//避免自动生成getter/setter方法


- (instancetype) init{
    self = [super init];
    if (self) {
        self.name = @"zhansan";
        self.age = 33;
    }
    return self;
}



- (void) func1{
    NSLog(@"执行func1");
}

- (void) func2{
    NSLog(@"执行func2");
}

//输出person对象的方法
- (NSString *)description{
    return [NSString stringWithFormat:@"name=%@,age=%ld",self.name,(long)self.age];
}
@end
