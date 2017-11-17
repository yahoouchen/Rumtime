# 什么是Rumtime

  我们写的代码在程序运行过程中都会被转化成runtime的C代码执行，例如[target doSomething];会被转化成objc_msgSend(target, @selector(doSomething));。 OC中一切都被设计成了对象，我们都知道一个类被初始化成一个实例，这个实例是一个对象。实际上一个类本质上也是一个对象，在runtime中用结构体表示。

Runtime的一切都围绕两个中心：类的动态配置 和 消息传递。

# Rumtime 常用场景

运行时修改内存中的数据

动态的在内存中创建一个类

给类增加一个属性

给类增加一个协议实现

给类增加一个方法实现IMP

遍历一个类的所有成员变量、属性和方法等

# 具体应用

拦截系统自带的方法调用（Method Swizzling黑魔法）

将某些OC代码转化为Runtime代码，探究底层。如block的实现原理

实现给分类增加属性

实现NSCoding的自动归档和接档

实现字典的模型和自动转换

JSPatch替换已有的OC方法实行等

# 具体实现

 首先，在需要调用Runtime相关方法和参数的地方添加头文件<objc/runtime.h>
 
/这里用新建Person类进行举列分析/

Person.h
```
#import <Foundation/Foundation.h>

@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property(nonatomic ,assign) NSInteger weidht;

- (void) func1;
- (void) func2;
@end

```
Person.m

```
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
```

## 1.获取person类的所有变量
```
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
```
## 2.获取person类的所有方法
SEL：数据类型，表示方法选择器，可以理解为对方法的一种包装。在每个方法都有一个与之对应的SEL类型的数据，根据一个SEL数据“@selector(方法名)”就可以找到对应的方法地址，进而调用方法。 因此可以通过：获取 Method结构体->得到SEL选择器名称->得到对应的方法名 ，这样的方式，便于认识OC中关于方法的定义。

```- (void) getAllMethod{
    unsigned int count;
    /获取方法列表，所有在.m文件显式实现的方法都会被找到，包括setter+getter方法；
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
```

## 3.改变person类的私有变量name的值
```
//3.改变person的name的变量属性
- (void)changeVariable{
    NSLog(@"改变前的person：%@",per.name);
    unsigned int count = 0;
    Ivar *allList = class_copyIvarList([Person class], &count);
    Ivar ivv = allList[0]; //从第一个例子getAllVariable中输出的控制台信息，我们可以看到name为第一个实例属性。
    object_setIvar(per, ivv, @"Mike"); //name属性Tom被强制改为Mike。
    NSLog(@"改变之后的person：%@",per.name);
}
```

## 4.为person的category类增加一个新属性

如何在不改动某个类的前提下，添加一个新的属性呢？ 答：可以利用runtime为分类添加新属性。 在iOS中，category，也就是分类，是不可以为本类添加新的属性的，但是在runtime中我们可以使用对象关联，为person类进行分类的新属性创建：

####使用场景：
假设imageCategory是UIImage类的分类，在实际开发中，我们使用UIImage下载图片或者操作过程需要增加一个URL保存一段地址，以备后期使用。这时可以尝试在分类中动态添加新属性MyURL进行存储。

首先新建一个类继承Person 命名PersonCategory

在出现的新类“person+PersonCategory.h”中，添加“height”：
```
#import "Person+PersonCategory.h"
#import <objc/objc-runtime.h>
const char *str = "mykey";//做为key，字符常量 必须是C语言字符串

@implementation Person (PersonCategory)

- (void)setHeight:(float)height{
    /*
     第一个参数是需要添加属性的对象；
     第二个参数是属性的key;
     第三个参数是属性的值,类型必须为id，所以此处height先转为NSNumber类型；
     第四个参数是使用策略，是一个枚举值，类似@property属性创建时设置的关键字，可从命名看出各枚举的意义；
     objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy);
     */
    
    NSNumber  *num = [NSNumber numberWithFloat:height];
    objc_setAssociatedObject(self, str, num, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//提取属性值
- (float)height{
    NSNumber *number =  objc_getAssociatedObject(self, str);
    return [number floatValue];
}

@end
```

接下来，我们可以在ViewController.m中对person的一个对象进行height的访问了，

```//4.添加的新属性
- (void)addVariable
{
    per.height = 12; //给新属性赋值
    NSLog(@"%f",[per height]);  //输出新属性的值
}
```

## 5.为person类添加一个新方法
```
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
```
## 6.交换person类的二个方法功能
 交换方法的使用场景：项目中的某个功能，在项目中需要多次被引用，当项目的需求发生改变时，要使用另一种功能代替这个功能，且要求不改变旧的项目(也就是不改变原来方法实现的前提下)。那么，我们可以在分类中，再写一个新的方法(符合新的需求的方法)，然后交换两个方法的实现。这样，在不改变项目的代码，而只是增加了新的代码的情况下，就完成了项目的改进，很好地体现了该项目的封装性与利用率。 注：交换两个方法的实现一般写在类的load方法里面，因为load方法会在程序运行前加载一次。
```
//6.交互person类的2个方法功能
- (void) replaceMethod{
    Method method1 = class_getInstanceMethod([Person class], @selector(func1));
    Method method2 = class_getInstanceMethod([Person class], @selector(func2));
    
    //执行交互方法
    method_exchangeImplementations(method1, method2);
    [per func1]; //输出交换后的效果，需要对比的可以尝试下交换前运行func1；
}
```
