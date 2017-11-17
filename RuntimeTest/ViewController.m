//
//  ViewController.m
//  RuntimeTest
//
//  Created by UCS on 2017/11/16.
//  Copyright © 2017年 UCS. All rights reserved.
//

#import "ViewController.h"
#import <objc/objc-runtime.h>
#import "Person.h"
#import "Person+PersonCategory.h"

@implementation ViewController{
    Person *per;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    per = [[Person alloc] init];
    
    //6个关于runtime机制方法的小例子
    [self getAllMethod];    //1.获取person类的所有变量
    [self getAllMethod];    //2.获取person类的所有方法
    [self changeVariable];  //3.改变person类的私有变量name的值
    [self addVariable];     //4.为person的category类增加一个新属性
    [self addMethod];       //5.为person类添加一个新方法
    [self replaceMethod];   //6.交换person类的二个方法功能
  
}

//1.获取person所有的成员变量
- (void)getAllVariable{
    unsigned int count = 0;
    //获取类的一个包含所有变量的列表，IVar是runtime声明的一个宏，是实例变量的意思.
    Ivar *allVariables = class_copyIvarList([Person class], &count);
    for(int i = 0;i<count;i++)
    {
        //遍历每一个变量，包括名称和类型（此处没有星号"*"）
        Ivar ivar = allVariables[i];
        const char *Variablename = ivar_getName(ivar); //获取成员变量名称
        const char *VariableType = ivar_getTypeEncoding(ivar); //获取成员变量类型
        NSLog(@"(Name: %s) ----- (Type:%s)",Variablename,VariableType);
    }
    
}


//2.获取person类的所有方法
- (void) getAllMethod{
    unsigned int count;
    //获取方法列表，所有在.m文件显式实现的方法都会被找到，包括setter+getter方法；
    Method *allMethods = class_copyMethodList([Person class], &count);
    for(int i =0;i<count;i++)
    {
        //Method，为runtime声明的一个宏，表示对一个方法的描述
        Method md = allMethods[i];
        //获取SEL：SEL类型,即获取方法选择器@selector()
        SEL sel = method_getName(md);
        //得到sel的方法名：以字符串格式获取sel的name，也即@selector()中的方法名称
        const char *methodname = sel_getName(sel); NSLog(@"(Method:%s)",methodname);
    }
}

//3.改变person的name的变量属性
- (void)changeVariable{
    NSLog(@"改变前的person：%@",per.name);
    unsigned int count = 0;
    Ivar *allList = class_copyIvarList([Person class], &count);
    Ivar ivv = allList[0]; //从第一个例子getAllVariable中输出的控制台信息，我们可以看到name为第一个实例属性。
    object_setIvar(per, ivv, @"Mike"); //name属性Tom被强制改为Mike。
    
    NSLog(@"改变之后的person：%@",per.name);
 
}

//4.添加的新属性
- (void)addVariable
{
    per.height = 12; //给新属性赋值
    NSLog(@"%f",[per height]);  //输出新属性的值
}

//5.为person类添加一个新方法
- (void)addMethod{
    /* 动态添加方法：
     第一个参数表示Class cls 类型；
     第二个参数表示待调用的方法名称；
     第三个参数(IMP)myAddingFunction，IMP一个函数指针，这里表示指定具体实现方法myAddingFunction；
     第四个参数表方法的参数，0代表没有参数；
     */
    class_addMethod([per class], @selector(NewMethod), (IMP)myAddingFunction, 0);
    //调用方法 【如果使用[per NewMethod]调用方法，在ARC下会报“no visible @interface"错误】
    
    if ([self respondsToSelector:@selector(NewMethod)]) {
        [self performSelector:@selector(NewMethod)];
    }else{
        NSLog(@"添加方法错误");
    }
}

    //具体的实现（方法的内部都默认包含两个参数Class类和SEL方法，被称为隐式参数。）
    int myAddingFunction(id self, SEL _cmd){
    NSLog(@"已新增方法:NewMethod");
    return 1;
}

//6.交互person类的2个方法功能
- (void) replaceMethod{
    Method method1 = class_getInstanceMethod([Person class], @selector(func1));
    Method method2 = class_getInstanceMethod([Person class], @selector(func2));
    
    //执行交互方法
    method_exchangeImplementations(method1, method2);
    [per func1]; //输出交换后的效果，需要对比的可以尝试下交换前运行func1；
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
