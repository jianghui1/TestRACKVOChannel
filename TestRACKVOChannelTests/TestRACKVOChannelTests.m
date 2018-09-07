//
//  TestRACKVOChannelTests.m
//  TestRACKVOChannelTests
//
//  Created by ys on 2018/9/3.
//  Copyright © 2018年 ys. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <ReactiveCocoa.h>

@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) Person *person;
@property (nonatomic, assign) int value;
@end

@implementation Person

@end

@interface TestRACKVOChannelTests : XCTestCase

@property (nonatomic, assign) NSInteger integerProperty;

@end

@implementation TestRACKVOChannelTests

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

@end
