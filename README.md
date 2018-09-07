##### `RACKVOChannel`作为`RACChannel`的子类，根据名字可以知道，主要用于`KVO`。

首先，看下`.h`文件：

    #define RACChannelTo(TARGET, ...) \
    metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) \
        (RACChannelTo_(TARGET, __VA_ARGS__, nil)) \
        (RACChannelTo_(TARGET, __VA_ARGS__))
这是一个宏定义，先看下这个宏的注释：
    
    /// Creates a RACKVOChannel to the given key path. When the targeted object
    /// deallocates, the channel will complete.
    根据`key path` 创建一个`RACKVOChannel`。当目标对象释放的时候，这个`channel`会完成。
    
    /// If RACChannelTo() is used as an expression, it returns a RACChannelTerminal that
    /// can be used to watch the specified property for changes, and set new values
    /// for it. The terminal will start with the property's current value upon
    /// subscription.
    如果这个宏被用作一个表达式，他返回一个可以用来观察指定属性变化的`RACChannelTerminal`对象，并且给他设置新的值。这个`terminal`将会以属性的当前值开始用于订阅。
    
    /// If RACChannelTo() is used on the left-hand side of an assignment, there must a
    /// RACChannelTerminal on the right-hand side of the assignment. The two will be
    /// subscribed to one another: the property's value is immediately set to the
    /// value of the channel terminal on the right-hand side, and subsequent changes
    /// to either terminal will be reflected on the other.
    如果这个宏被用在等式的左边，那等式的右端必须有一个`RACChannelTerminal`。这两个将会互相订阅：立即给等式右边的`channel terminal`设置属性值，以及一个`terminal`的后面的变化会反映到另一个`terminal`上。
    
    /// There are two different versions of this macro:
    ///
    ///  - RACChannelTo(TARGET, KEYPATH, NILVALUE) will create a channel to the `KEYPATH`
    ///    of `TARGET`. If the terminal is ever sent a `nil` value, the property will
    ///    be set to `NILVALUE` instead. `NILVALUE` may itself be `nil` for object
    ///    properties, but an NSValue should be used for primitive properties, to
    ///    avoid an exception if `nil` is sent (which might occur if an intermediate
    ///    object is set to `nil`).
    ///  - RACChannelTo(TARGET, KEYPATH) is the same as the above, but `NILVALUE` defaults to
    ///    `nil`.
    这里有两种关于这个宏不同的版本。
    `RACChannelTo(TARGET, KEYPATH, NILVALUE)`将会给`TARGET`的`KEYPATH`创建一个`channel`。如果这
    个`terminal`被设置为`nil`，那么属性将会被设置为`NILVALUE`。对于对象属性，`NILVALUE`可能会是`nil`，但是一个`NSValue`应当用于简单的属性来避免`nil`导致的异常（这可能发生在一个中间对象设置
    成`nil`）。
    `RACChannelTo(TARGET, KEYPATH)`与上面一样，只是`NILVALUE`默认为`nil`。
    
    例子如下：
    /// Examples
    ///
    ///  RACChannelTerminal *integerChannel = RACChannelTo(self, integerProperty, @42);
    ///
    ///  // Sets self.integerProperty to 5.
    ///  [integerChannel sendNext:@5];
    ///
    ///  // Logs the current value of self.integerProperty, and all future changes.
    ///  [integerChannel subscribeNext:^(id value) {
    ///      NSLog(@"value: %@", value);
    ///  }];
    ///
    ///  // Binds properties to each other, taking the initial value from the right
    ///  side.
    ///  RACChannelTo(view, objectProperty) = RACChannelTo(model, objectProperty);
    ///  RACChannelTo(view, integerProperty, @2) = RACChannelTo(model, integerProperty, @10);
上面，把`RACChannelTo`的注释分析完了。然后宏的定义中通过`metamacro_if_eq`来调用`(RACChannelTo_(TARGET, __VA_ARGS__, nil))` or `(RACChannelTo_(TARGET, __VA_ARGS__))`。

    /// Do not use this directly. Use the RACChannelTo macro above.
    #define RACChannelTo_(TARGET, KEYPATH, NILVALUE) \
        [[RACKVOChannel alloc] initWithTarget:(TARGET) keyPath:@keypath(TARGET, KEYPATH) nilValue:(NILVALUE)][@keypath(RACKVOChannel.new, followingTerminal)]
该宏不应该直接使用。实际作用是通过`RACKVOChannel`的实例化方法生成`RACKVOChannel`对象。

接着，看下类中的方法。
    
    /// Initializes a channel that will observe the given object and key path.
    ///
    /// The current value of the key path, and future KVO notifications for the given
    /// key path, will be sent to subscribers of the channel's `followingTerminal`.
    /// Values sent to the `followingTerminal` will be set at the given key path using
    /// key-value coding.
    ///
    /// When the target object deallocates, the channel will complete. Signal errors
    /// are considered undefined behavior.
    ///
    /// This is the designated initializer for this class.
    ///
    /// target   - The object to bind to.
    /// keyPath  - The key path to observe and set the value of.
    /// nilValue - The value to set at the key path whenever a `nil` value is
    ///            received. This may be nil when connecting to object properties, but
    ///            an NSValue should be used for primitive properties, to avoid an
    ///            exception if `nil` is received (which might occur if an intermediate
    ///            object is set to `nil`).
    - (id)initWithTarget:(__weak NSObject *)target keyPath:(NSString *)keyPath nilValue:(id)nilValue;
    
    - (id)init __attribute__((unavailable("Use -initWithTarget:keyPath:nilValue: instead")));
`init`不可以用来初始化，该类的初始化只能通过`initWithTarget:keyPath:nilValue:`完成初始化。该类的注释翻译如下：

    初始化一个`channel`观察给定对象的`key path`。
    
    `key path`当前的值，以及以后`KVO`的通知值，都会被发送给`channel`的`followingTerminal`的订阅者。
    `followingTerminal`发送的值将会使用`KVC`的方式设置给对象的`key path`。
    
    当目标对象释放了，这个`channel`也会完成。错误信号会有不确定的行为。
    
    这是这个类指定初始化方法。
    
    `target` - 被绑定的目标对象。
    `keyPath` - 被观察和设置值的`keyPath`。
    `nilValue` - 当收到`nil`值，将`nilValue`设置给`keyPath`。当连接一个对象的属性的时候这个值可能是`nil`，但是一个`NSValue`应该用原始属性，来避免收到`nil`导致的异常（中间对象被设置为`nil`可能发生
    ）。

接下来是`RACKVOChannel`的类目，

注释如下：
    
    /// Methods needed for the convenience macro. Do not call explicitly.
这个类目提供的是宏定义所需要的一些方法， 不应该显式调用。

方法如下：

    - (RACChannelTerminal *)objectForKeyedSubscript:(NSString *)key;
    - (void)setObject:(RACChannelTerminal *)otherTerminal forKeyedSubscript:(NSString *)key;
这两个方法也就是为了使该类可以通过`key-value`方式取值的。如上面的宏`[[RACKVOChannel alloc] initWithTarget:(TARGET) keyPath:@keypath(TARGET, KEYPATH) nilValue:(NILVALUE)][@keypath(RACKVOChannel.new, followingTerminal)]`，通过字面量的方式获取值。

上面把相关的方法分析完了，接着看看`.m`中的实现。

里面新定义了一个类`RACKVOChannelData`。提供了`dataForChannel:`方法用于初始化。注意这个方法的参数为`channel`，所以这个类与`channel`是相关联的。

`RACKVOChannel`中定义了一些属性:
* `target` 目标对象。
* `keyPath` 目标对象的`keyPath`。
* `currentThreadData` `RACKVOChannelData`对象。

方法：
* `- (void)createCurrentThreadData;` 创建一个`RACKVOChannelData`对象。
* `- (void)destroyCurrentThreadData;` 销毁一个`RACKVOChannelData`对象。

接着就是方法的实现:

    - (RACKVOChannelData *)currentThreadData {
    	NSMutableArray *dataArray = NSThread.currentThread.threadDictionary[RACKVOChannelDataDictionaryKey];
    
    	for (RACKVOChannelData *data in dataArray) {
    		if (data.owner == (__bridge void *)self) return data;
    	}
    
    	return nil;
    }
实现`currentThreadData`的get方法，根据`RACKVOChannelDataDictionaryKey`获取到一个数组，然后遍历数组拿到`RACKVOChannelData`对象。

    - (id)initWithTarget:(__weak NSObject *)target keyPath:(NSString *)keyPath nilValue:(id)nilValue {
    	NSCParameterAssert(keyPath.rac_keyPathComponents.count > 0);
    
    	NSObject *strongTarget = target;
    
    	self = [super init];
    	if (self == nil) return nil;
    
    	_target = target;
    	_keyPath = [keyPath copy];
    
    	[self.leadingTerminal setNameWithFormat:@"[-initWithTarget: %@ keyPath: %@ nilValue: %@] -leadingTerminal", target, keyPath, nilValue];
    	[self.followingTerminal setNameWithFormat:@"[-initWithTarget: %@ keyPath: %@ nilValue: %@] -followingTerminal", target, keyPath, nilValue];
    
    	if (strongTarget == nil) {
    		[self.leadingTerminal sendCompleted];
    		return self;
    	}
    
    	// Observe the key path on target for changes and forward the changes to the
    	// terminal.
    	//
    	// Intentionally capturing `self` strongly in the blocks below, so the
    	// channel object stays alive while observing.
    	RACDisposable *observationDisposable = [strongTarget rac_observeKeyPath:keyPath options:NSKeyValueObservingOptionInitial observer:nil block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
    		// If the change wasn't triggered by deallocation, only affects the last
    		// path component, and ignoreNextUpdate is set, then it was triggered by
    		// this channel and should not be forwarded.
    		if (!causedByDealloc && affectedOnlyLastComponent && self.currentThreadData.ignoreNextUpdate) {
    			[self destroyCurrentThreadData];
    			return;
    		}
    
    		[self.leadingTerminal sendNext:value];
    	}];
    
    	NSString *keyPathByDeletingLastKeyPathComponent = keyPath.rac_keyPathByDeletingLastKeyPathComponent;
    	NSArray *keyPathComponents = keyPath.rac_keyPathComponents;
    	NSUInteger keyPathComponentsCount = keyPathComponents.count;
    	NSString *lastKeyPathComponent = keyPathComponents.lastObject;
    
    	// Update the value of the property with the values received.
    	[[self.leadingTerminal
    		finally:^{
    			[observationDisposable dispose];
    		}]
    		subscribeNext:^(id x) {
    			// Check the value of the second to last key path component. Since the
    			// channel can only update the value of a property on an object, and not
    			// update intermediate objects, it can only update the value of the whole
    			// key path if this object is not nil.
    			NSObject *object = (keyPathComponentsCount > 1 ? [self.target valueForKeyPath:keyPathByDeletingLastKeyPathComponent] : self.target);
    			if (object == nil) return;
    
    			// Set the ignoreNextUpdate flag before setting the value so this channel
    			// ignores the value in the subsequent -didChangeValueForKey: callback.
    			[self createCurrentThreadData];
    			self.currentThreadData.ignoreNextUpdate = YES;
    
    			[object setValue:x ?: nilValue forKey:lastKeyPathComponent];
    		} error:^(NSError *error) {
    			NSCAssert(NO, @"Received error in %@: %@", self, error);
    
    			// Log the error if we're running with assertions disabled.
    			NSLog(@"Received error in %@: %@", self, error);
    		}];
    
    	// Capture `self` weakly for the target's deallocation disposable, so we can
    	// freely deallocate if we complete before then.
    	@weakify(self);
    
    	[strongTarget.rac_deallocDisposable addDisposable:[RACDisposable disposableWithBlock:^{
    		@strongify(self);
    		[self.leadingTerminal sendCompleted];
    		self.target = nil;
    	}]];
    
    	return self;
    }
指定初始化方法。分步骤分析：
1. 将`target` `keyPath`保存到实例变量中。
2. `self.leadingTerminal` `self.followingTerminal`设置名字。
3. 检验`target`对象是否存在。如果不存在，`self.leadingTerminal`发送完成事件，函数返回；如果存在；继续进行。
4. 调用`NSObject (RACKVOWrapper)`中的`rac_observeKeyPath:options:observer:block:`方法观察目标对象的`keyPath`的变化。回调中根据参数判断执行`destroyCurrentThreadData`方法，还是将`value`值发送出去。
5. 接下来拿到`keyPath`的不同元素值。
6. 对`self.leadingTerminal`进行订阅。主要逻辑在`subscribeNext:`中：

    * 如果`keyPath`由多个字段组成，那么就获取`keyPath`中倒数第二个位置的对象；如果`keyPath`只有一个字段，那么就获取对象本身。这样保证仅仅更新一个对象的一个属性。
    * 调用`createCurrentThreadData`方法存储`self`。
    * 设置`ignoreNextUpdate`为`YES`，保证忽略掉`didChangeValueForKey:`的回调。
    * 通过`setValue:forKey:`给对象设置值。
7. 在对象的清理对象中添加一个清理对象，该清理对象的清理任务是发送完成信息，并将`target`的引用置为`nil`。


    - (void)createCurrentThreadData {
    	NSMutableArray *dataArray = NSThread.currentThread.threadDictionary[RACKVOChannelDataDictionaryKey];
    	if (dataArray == nil) {
    		dataArray = [NSMutableArray array];
    		NSThread.currentThread.threadDictionary[RACKVOChannelDataDictionaryKey] = dataArray;
    		[dataArray addObject:[RACKVOChannelData dataForChannel:self]];
    		return;
    	}
    
    	for (RACKVOChannelData *data in dataArray) {
    		if (data.owner == (__bridge void *)self) return;
    	}
    
    	[dataArray addObject:[RACKVOChannelData dataForChannel:self]];
    }
该方法以`self`为参数生成一个`RACKVOChannelData`对象，然后存到数组`dataArray`中，而`dataArray`存放在`NSThread.currentThread.threadDictionary`。


    - (void)destroyCurrentThreadData {
    	NSMutableArray *dataArray = NSThread.currentThread.threadDictionary[RACKVOChannelDataDictionaryKey];
    	NSUInteger index = [dataArray indexOfObjectPassingTest:^ BOOL (RACKVOChannelData *data, NSUInteger idx, BOOL *stop) {
    		return data.owner == (__bridge void *)self;
    	}];
    
    	if (index != NSNotFound) [dataArray removeObjectAtIndex:index];
    }
该方法将`NSThread.currentThread.threadDictionary`中存储的`RACKVOChannelData`对象删除掉。

接下来是`RACKVOChannel (RACChannelTo)`类目的方法实现：

    - (RACChannelTerminal *)objectForKeyedSubscript:(NSString *)key {
    	NSCParameterAssert(key != nil);
    
    	RACChannelTerminal *terminal = [self valueForKey:key];
    	NSCAssert([terminal isKindOfClass:RACChannelTerminal.class], @"Key \"%@\" does not identify a channel terminal", key);
    
    	return terminal;
    }
通过`valueForKey:`获取到一个对象并返回出去。

    - (void)setObject:(RACChannelTerminal *)otherTerminal forKeyedSubscript:(NSString *)key {
    	NSCParameterAssert(otherTerminal != nil);
    
    	RACChannelTerminal *selfTerminal = [self objectForKeyedSubscript:key];
    	[otherTerminal subscribe:selfTerminal];
    	[[selfTerminal skip:1] subscribe:otherTerminal];
    }
通过`objectForKeyedSubscript:`获取到`key`对应的对象`selfTerminal`，然后`otherTerminal`与`selfTerminal`相互订阅，达到`key`对应的对象就是`otherTerminal`的效果。这里调用`skip:`函数是为了忽略之前的值，也就是保证只对以后的值有效。这样才符合正常的逻辑（总不能现在设置的对象，还能够获取的以前的值吧）。

完整测试用例在[这里](https://github.com/jianghui1/TestRACKVOChannel)。

    - (void)test_objectRelease
    {
        void (^testBlock)(void);
        @autoreleasepool {
            testBlock = ^(void){
                NSIndexPath *indexPath = [[NSIndexPath alloc] init];
                id x = RACChannelTo(indexPath, length);
                NSLog(@"x -- %@", x);
                [RACChannelTo(indexPath, length) subscribeNext:^(id x) {
                    NSLog(@"objectRelease -- next -- %@", x);
                } error:^(NSError *error) {
                    NSLog(@"objectRelease -- error");
                } completed:^{
                    NSLog(@"objectRelease -- completed");
                }];
                [indexPath.rac_willDeallocSignal subscribeNext:^(id x) {
                    NSLog(@"111111");
                } error:^(NSError *error) {
                    NSLog(@"222222");
                } completed:^{
                    NSLog(@"333333");
                }];
            };
        }
        testBlock();
        NSLog(@"finished");
        // 打印日志：
        /*
         2018-09-03 18:08:05.248582+0800 TestRACKVOChannel[68679:3857179] x -- <RACChannelTerminal: 0x604000220ce0> name:
         2018-09-03 18:08:05.249317+0800 TestRACKVOChannel[68679:3857179] objectRelease -- next -- 0
         2018-09-03 18:08:05.249829+0800 TestRACKVOChannel[68679:3857179] objectRelease -- completed
         2018-09-03 18:08:05.250107+0800 TestRACKVOChannel[68679:3857179] 333333
         2018-09-03 18:08:05.250280+0800 TestRACKVOChannel[68679:3857179] finished
         */
    }
    
    - (void)test_objectValue
    {
        NSURL *url = [NSURL URLWithString:@"xxx"];
        [RACChannelTo(url, absoluteString) subscribeNext:^(id x) {
            NSLog(@"objectValue -- %@", x);
        }];
        // 打印日志：
        /*
         2018-09-03 18:10:41.637527+0800 TestRACKVOChannel[68816:3865455] objectValue -- xxx
         */
    }
    
    - (void)test_assignLeft
    {
        Person *person1 = [[Person alloc] init];
        person1.name = @"xxx";
        Person *person2 = [[Person alloc] init];
        
        RACChannelTerminal *t1 = RACChannelTo(person1, name);
        RACChannelTerminal *t2 = RACChannelTo(person2, name);
        t1 = t2;
        
        [t1 subscribeNext:^(id x) {
            NSLog(@"assignLeft -- person1 -- %@", x);
        }];
        
        [t2 subscribeNext:^(id x) {
            NSLog(@"assignLeft -- person2 -- %@", x);
        }];
        
        person1.name = @"111";
        person2.name = @"222";
        person1.name = @"111";
        
        // 打印日志：
        /*
         2018-09-07 19:44:53.288422+0800 TestRACKVOChannel[83516:10605027] assignLeft -- person1 -- (null)
         2018-09-07 19:44:53.288654+0800 TestRACKVOChannel[83516:10605027] assignLeft -- person2 -- (null)
         2018-09-07 19:44:53.289223+0800 TestRACKVOChannel[83516:10605027] assignLeft -- person1 -- 222
         2018-09-07 19:44:53.289471+0800 TestRACKVOChannel[83516:10605027] assignLeft -- person2 -- 222
         */
    }
    
    - (void)test_defaultValue
    {
        Person *person1 = [[Person alloc] init];
        person1.name = @"111";
        
        RACChannelTerminal *t = RACChannelTo(person1, name, @"xxx");
        [t subscribeNext:^(id x) {
            NSLog(@"defaultValue -- person1 -- %@", x);
        }];
        
        person1.name = nil;
        person1.name = @"111";
        [t sendNext:nil];
        NSLog(@"person1 -- %@", person1.name);
        [t sendNext:@"111"];
        NSLog(@"person1 -- %@", person1.name);
        
        // 打印日志：
        /*
         2018-09-07 19:58:16.114824+0800 TestRACKVOChannel[84107:10645989] defaultValue -- person1 -- 111
         2018-09-07 19:58:16.115331+0800 TestRACKVOChannel[84107:10645989] defaultValue -- person1 -- (null)
         2018-09-07 19:58:16.115639+0800 TestRACKVOChannel[84107:10645989] defaultValue -- person1 -- 111
         2018-09-07 19:58:19.421380+0800 TestRACKVOChannel[84107:10645989] person1 -- xxx
         2018-09-07 19:58:19.421651+0800 TestRACKVOChannel[84107:10645989] person1 -- 111
         */
    }
    
    - (void)test_defaultValue1
    {
        Person *person = [[Person alloc] init];
        person.value = 1;
        
        RACChannelTerminal *t = RACChannelTo(person, value, @6);
        [t subscribeNext:^(id x) {
            NSLog(@"defaultValue1 -- person -- %@", x);
        }];
        
        [t sendNext:nil];
        NSLog(@"person -- %d", person.value);
        [t sendNext:@"111"];
        NSLog(@"person -- %d", person.value);
        
        // 打印日志：
        /*
         2018-09-07 20:09:24.039908+0800 TestRACKVOChannel[84609:10679989] defaultValue1 -- person -- 1
         2018-09-07 20:09:24.040277+0800 TestRACKVOChannel[84609:10679989] person -- 6
         2018-09-07 20:09:24.040544+0800 TestRACKVOChannel[84609:10679989] person -- 111
         */
    }
    
    - (void)test_defaultValue2
    {
        Person *person = [[Person alloc] init];
        person.value = 1;
    
        RACChannelTerminal *t = RACChannelTo(person, value);
        [t subscribeNext:^(id x) {
            NSLog(@"defaultValue1 -- person -- %@", x);
        }];
    
        [t sendNext:nil];
        NSLog(@"person -- %d", person.value);
        [t sendNext:@"111"];
        NSLog(@"person -- %d", person.value);
    
        // 打印日志：
        /*
         2018-09-07 20:10:04.779842+0800 TestRACKVOChannel[84648:10682324] defaultValue1 -- person -- 1
         /Users/ys/Desktop/TestRACKVOChannel/Pods/ReactiveCocoa/ReactiveCocoa/RACKVOChannel.m:131: error: -[TestRACKVOChannelTests test_defaultValue2] : failed: caught "NSInvalidArgumentException", "[<Person 0x604000220d80> setNilValueForKey]: could not set nil as the value for the key value."
         */
    }
    
    - (void)test_initWithTarget
    {
        RACKVOChannel *channel = [[RACKVOChannel alloc] initWithTarget:nil keyPath:@"x" nilValue:nil];
        [channel.followingTerminal subscribeNext:^(id x) {
            NSLog(@"initWithTarget -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"initWithTarget -- error");
        } completed:^{
            NSLog(@"initWithTarget -- completed");
        }];
        // 打印日志：
        /*
         2018-09-05 18:19:01.996935+0800 TestRACKVOChannel[51978:7093207] initWithTarget -- completed
         */
    }
    
    - (void)test_initWithTarget1
    {
        Person *person = [[Person alloc] init];
        RACKVOChannel *channel = [[RACKVOChannel alloc] initWithTarget:person keyPath:@"name" nilValue:nil];
        [channel.followingTerminal subscribeNext:^(id x) {
            NSLog(@"channel -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"channel -- error");
        } completed:^{
            NSLog(@"channel -- completed");
        }];
        person.name = @"111";
        person.name = @"222";
        // 打印日志：
        /*
         2018-09-05 18:21:13.890100+0800 TestRACKVOChannel[52108:7096914] channel -- (null)
         2018-09-05 18:21:13.891254+0800 TestRACKVOChannel[52108:7096914] channel -- 111
         2018-09-05 18:21:13.891982+0800 TestRACKVOChannel[52108:7096914] channel -- 222
         2018-09-05 18:21:13.892426+0800 TestRACKVOChannel[52108:7096914] channel -- completed
         */
    }
    
    - (void)test_initWithTarget2
    {
        Person *person = [[Person alloc] init];
        Person *nPerson = [[Person alloc] init];
        Person *nnPerson = [[Person alloc] init];
        person.person = nPerson;
        nPerson.person = nnPerson;
        RACKVOChannel *channel = [[RACKVOChannel alloc] initWithTarget:person keyPath:@"person.person.name" nilValue:nil];
        [channel.followingTerminal subscribeNext:^(id x) {
            NSLog(@"channel -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"channel -- error");
        } completed:^{
            NSLog(@"channel -- completed");
        }];
        nnPerson.name = @"nnperson";
        nPerson.name = @"nperson";
        person.name = @"person";
        // 打印日志：
        /*
         2018-09-05 18:26:29.194820+0800 TestRACKVOChannel[52399:7106058] channel -- (null)
         2018-09-05 18:26:29.195286+0800 TestRACKVOChannel[52399:7106058] channel -- nnperson
         2018-09-05 18:26:29.195911+0800 TestRACKVOChannel[52399:7106058] channel -- completed
         */
    }
    
    - (void)test_initWithTarget3
    {
        Person *person = [[Person alloc] init];
        Person *nPerson = [[Person alloc] init];
        Person *nnPerson = [[Person alloc] init];
        person.person = nPerson;
        nPerson.person = nnPerson;
        RACKVOChannel *channel = [[RACKVOChannel alloc] initWithTarget:person keyPath:@"person.person.name" nilValue:nil];
        [channel.followingTerminal subscribeNext:^(id x) {
            NSLog(@"channel -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"channel -- error");
        } completed:^{
            NSLog(@"channel -- completed");
        }];
        [channel.followingTerminal sendNext:@"xxxxx"];
        NSLog(@"nnperson -- %@", nnPerson.name);
        NSLog(@"nperson -- %@", nPerson.name);
        NSLog(@"person -- %@", person.name);
        // 打印日志：
        /*
         2018-09-07 20:30:04.708969+0800 TestRACKVOChannel[85422:10739392] channel -- (null)
         2018-09-07 20:30:04.709409+0800 TestRACKVOChannel[85422:10739392] nnperson -- xxxxx
         2018-09-07 20:30:04.709758+0800 TestRACKVOChannel[85422:10739392] nperson -- (null)
         2018-09-07 20:30:04.709919+0800 TestRACKVOChannel[85422:10739392] person -- (null)
         2018-09-07 20:30:04.710376+0800 TestRACKVOChannel[85422:10739392] channel -- completed
         */
    }
    
    - (void)test_objectForKeyedSubscript
    {
        RACKVOChannel *channel = [[RACKVOChannel alloc] initWithTarget:nil keyPath:@"xxx" nilValue:nil];
        RACChannelTerminal *leadingTerminal = channel[@"leadingTerminal"];
        RACChannelTerminal *followingTerminal = channel[@"followingTerminal"];
        NSLog(@"objectForKeyedSubscript -- %@ -- %@", leadingTerminal, channel.leadingTerminal);
        NSLog(@"objectForKeyedSubscript -- %@ -- %@", followingTerminal, channel.followingTerminal);
        // 打印日志：
        /*
         2018-09-05 18:30:56.059122+0800 TestRACKVOChannel[52645:7114225] objectForKeyedSubscript -- <RACChannelTerminal: 0x60400003b960> name:  -- <RACChannelTerminal: 0x60400003b960> name:
         2018-09-05 18:30:56.061642+0800 TestRACKVOChannel[52645:7114225] objectForKeyedSubscript -- <RACChannelTerminal: 0x60400003baa0> name:  -- <RACChannelTerminal: 0x60400003baa0> name:
         */
    }
    
    - (void)test_setObject_forKeyedSubscript
    {
        Person *person = [[Person alloc] init];
        RACKVOChannel *channel = [[RACKVOChannel alloc] initWithTarget:person keyPath:@"name" nilValue:nil];
        RACChannelTerminal *leadingTerminal = channel[@"leadingTerminal"];
        RACChannelTerminal *followingTerminal = channel[@"followingTerminal"];
        [leadingTerminal subscribeNext:^(id x) {
            NSLog(@"setObject_forKeyedSubscript -- leadingTerminal -- %@", x);
        }];
        [followingTerminal subscribeNext:^(id x) {
            NSLog(@"setObject_forKeyedSubscript -- followingTerminal -- %@", x);
        }];
        
        person.name = @"111";
        person.name = @"222";
        
        RACChannel *c = [[RACChannel alloc] init];
        [c.leadingTerminal subscribeNext:^(id x) {
            NSLog(@"setObject_forKeyedSubscript -- c -- leadingTerminal -- %@", x);
        }];
        [c.followingTerminal subscribeNext:^(id x) {
            NSLog(@"setObject_forKeyedSubscript -- c -- followingTerminal -- %@", x);
        }];
        
        RACSubject *subject = [RACSubject subject];
        [subject subscribeNext:^(id x) {
            NSLog(@"setObject_forKeyedSubscript -- subject -- %@", x);
        }];
        
        person.name = @"333";
        person.name = @"444";
        
        [channel.followingTerminal subscribe:subject];
        channel[@"followingTerminal"] = c.followingTerminal;
        
        person.name = @"555";
        person.name = @"666";
        // 打印日志：
        /*
         2018-09-07 19:26:56.048024+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- followingTerminal -- (null)
         2018-09-07 19:26:56.048409+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- followingTerminal -- 111
         2018-09-07 19:26:56.048599+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- followingTerminal -- 222
         2018-09-07 19:26:56.048920+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- followingTerminal -- 333
         2018-09-07 19:26:56.049116+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- followingTerminal -- 444
         2018-09-07 19:26:56.049244+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- subject -- 444
         2018-09-07 19:26:56.049529+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- followingTerminal -- 555
         2018-09-07 19:26:56.049629+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- subject -- 555
         2018-09-07 19:26:56.049766+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- c -- leadingTerminal -- 555
         2018-09-07 19:26:56.049925+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- followingTerminal -- 666
         2018-09-07 19:26:56.051151+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- subject -- 666
         2018-09-07 19:26:56.053572+0800 TestRACKVOChannel[82793:10553073] setObject_forKeyedSubscript -- c -- leadingTerminal -- 666
         */
    }
