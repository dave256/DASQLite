//
//  TestDASQLite.m
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//



#import <GHUnit/GHUnit.h>

#import "FMDatabase.h"
#import "Person.h"
#import "Course.h"

@interface TestDASQLite : GHTestCase {

    FMDatabase *db;

}

@end



@implementation TestDASQLite


- (BOOL)shouldRunOnMainThread {
    // By default NO, but if you have a UI test or test dependent on running on the main thread return YES
    //return NO;
    return YES;
}

- (void)setUpClass {
    // Run at start of all tests in the class
}

- (void)tearDownClass {
    // Run at end of all tests in the class
}

- (void)setUp {
    // Run before each test method
    system("/bin/rm -f /tmp/testdasqlite.db");
    system("touch /tmp/testdasqlite.db");
    db = [[FMDatabase alloc] initWithPath:@"/tmp/testdasqlite.db"];
    GHAssertEquals([db open], YES, @"failed to open database");
    
    [db beginTransaction];
    GHAssertEquals([db executeUpdate:@"create table person (pkey integer primary key, lastName text, firstName text, position integer, aDate real)"], YES, @"create table failed");
    GHAssertEquals([db executeUpdate:@"insert into person (lastName, firstName, position, aDate) values ('Reed', 'Dave', 2, 1289507894.9236939)"], YES, @"insert failed");
    GHAssertEquals([db executeUpdate:@"insert into person (lastName, firstName, position, aDate) values ('Stroeh', 'John', 3, 1289517894.9236939)"], YES, @"insert failed");
    GHAssertEquals([db executeUpdate:@"insert into person (lastName, firstName, position, aDate) values ('Anderson', 'Matt', 1, 1289515894.9236939)"], YES, @"insert failed");
    
    GHAssertEquals([db executeUpdate:@"create table course (pkey integer primary key, name text, position integer)"], YES, @"create table failed");
    GHAssertEquals([db executeUpdate:@"insert into course (name, position) values ('CS161', 2)"], YES, @"insert failed");
    GHAssertEquals([db executeUpdate:@"insert into course (name, position) values ('CS160', 1)"], YES, @"insert failed");

    [db commit];
    //GHAssertEquals([db commit], YES, @"failed to commit setUp");
}

- (void)tearDown {
    // Run after each test method
    [db close];
    [db release];
}

#pragma mark -------------------- tests --------------------

- (void)testSelectAllWhereForAll {
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    for (Person *p in people) {
        //GHTestLog(@"%@", p);
    }
    GHAssertEquals([people count], (NSUInteger)3, @"[people count] should be 3 for original file");
}

- (void)testSelectAllWhere {
    NSArray *people;
    
    people = [Person database:db selectAllWhere:@"where position<=2" orderBy:@"order by position"];
    /*
    for (Person *p in people) {
        GHTestLog(@"%@", p);
    }
     */
    GHAssertEquals([people count], (NSUInteger)2, @"[people count] should be 2 for original file with position <= 2");
}

- (void)testSelectOne {
    Person *p = [Person database:db selectOneWhere:@"where lastName='Reed'" orderBy:nil];
    GHAssertEqualStrings(p.firstName, @"Dave", @"testSelectOne firstName");
    GHAssertEqualStrings(p.lastName, @"Reed", @"testSelectOne lastName");
}

- (void)testInsert {
    Person *p = [[Person alloc] init];
    p.firstName = @"John";
    p.lastName = @"Doe";
    for (int i=4; i<1004; ++i) {
        p.position = i;
        [p insert:db];
        GHAssertEquals(p.pkey, i, @"in theory this could be wrong if pkeys not in order");
    }
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1003, @"[people count] should be 1003 after insert");

    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1001, @"[people count] should be 1001 for John");
}

- (void)testInsertNoTransaction {
    Person *p = [[Person alloc] init];
    p.firstName = @"John";
    p.lastName = @"Doe";
    [db beginTransaction];
    for (int i=4; i<1004; ++i) {
        p.position = i;
        [p insertNoTransaction:db];
    }
    [db commit];
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1003, @"[people count] should be 1003 after insert");
    
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1001, @"[people count] should be 1001 for John");
}

- (void)testUpdate {
    Person *p1 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    p1.lastName = @"Lewis";
    [p1 update:db];
    p1.position = 100;
    [p1 update:db];
    NSArray *people = [Person database:db selectAllWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1, @"[people count] should be 1 for Matt");
    Person *p2 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEqualStrings(p2.firstName, @"Matt", @"firstName");
    GHAssertEqualStrings(p2.lastName, @"Lewis", @"lastName");
    GHAssertEquals(p2.position, 100, @"position");
    
    p2.lastName = @"Anderson";
    p2.position = 1;
    NSDate *now = [NSDate date];
    p2.aDate = now;
    [p2 insert:db];
    
    people = [Person database:db selectAllWhere:@"where firstName='Matt'" orderBy:@"order by lastName, firstName"];
    GHAssertEquals([people count], (NSUInteger)2, @"[people count] should be 2 for Matt after insert");
    p1 = [people objectAtIndex:0];
    p2 = [people objectAtIndex:1];
    GHAssertEqualStrings(p1.firstName, @"Matt", @"firstName");
    GHAssertEqualStrings(p1.lastName, @"Anderson", @"lastName");
    GHAssertEquals(p1.position, 1, @"position");
    GHAssertEqualStrings([p1.aDate description], [now description], @"date should match after insert");
    
    
    GHAssertEqualStrings(p2.firstName, @"Matt", @"firstName");
    GHAssertEqualStrings(p2.lastName, @"Lewis", @"lastName");
    GHAssertEquals(p2.position, 100, @"position");
}

- (void)testUpdateNoTransaction {
    Person *p1 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    p1.lastName = @"Lewis";
    [db beginTransaction];
    [p1 updateNoTransaction:db];
    p1.position = 100;
    [p1 updateNoTransaction:db];
    NSArray *people = [Person database:db selectAllWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1, @"[people count] should be 1 for Matt");
    Person *p2 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEqualStrings(p2.firstName, @"Matt", @"firstName");
    GHAssertEqualStrings(p2.lastName, @"Lewis", @"lastName");
    GHAssertEquals(p2.position, 100, @"position");
    
    p2.lastName = @"Anderson";
    p2.position = 1;
    NSDate *now = [NSDate date];
    p2.aDate = now;
    [p2 insertNoTransaction:db];
    [db commit];
    
    people = [Person database:db selectAllWhere:@"where firstName='Matt'" orderBy:@"order by lastName, firstName"];
    GHAssertEquals([people count], (NSUInteger)2, @"[people count] should be 2 for Matt after insert");
    p1 = [people objectAtIndex:0];
    p2 = [people objectAtIndex:1];
    GHAssertEqualStrings(p1.firstName, @"Matt", @"firstName");
    GHAssertEqualStrings(p1.lastName, @"Anderson", @"lastName");
    GHAssertEquals(p1.position, 1, @"position");
    GHAssertEqualStrings([p1.aDate description], [now description], @"date should match after insert");
    
    GHAssertEqualStrings(p2.firstName, @"Matt", @"firstName");
    GHAssertEqualStrings(p2.lastName, @"Lewis", @"lastName");
    GHAssertEquals(p2.position, 100, @"position");
}

- (void)testDelete {
    Person *p = [[Person alloc] init];
    p.firstName = @"John";
    p.lastName = @"Doe";
    [db beginTransaction];
    for (int i=4; i<1004; ++i) {
        p.position = i;
        [p insertNoTransaction:db];
    }
    [db commit];
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1003, @"[people count] should be 1003 after insert");
    
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1001, @"[people count] should be 1001 for John");
    
    for (Person *p in people) {
        [p delete:db];
    }
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)0, @"[people count] should be 0 for John");
    people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)2, @"[people count] should be 2");
}

- (void)testDeleteNoTransaction {
    Person *p = [[Person alloc] init];
    p.firstName = @"John";
    p.lastName = @"Doe";
    [db beginTransaction];
    for (int i=4; i<1004; ++i) {
        p.position = i;
        [p insertNoTransaction:db];
    }
    [db commit];
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1003, @"[people count] should be 1003 after insert");
    
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1001, @"[people count] should be 1001 for John");
    
    [db beginTransaction];
    for (Person *p in people) {
        [p deleteNoTransaction:db];
    }
    [db commit];
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)0, @"[people count] should be 0 for John");
    people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)2, @"[people count] should be 2");
}

- (void)testSecondType {
    Course *c;
    c = [Course database:db selectOneWhere:nil orderBy:@"order by position"];
    GHAssertEqualStrings(c.name, @"CS160", @"course should be CS160");
    GHAssertEquals(c.position, 1, @"CS160 position should be 1");
    c = [Course database:db selectOneWhere:@"where position=2" orderBy:nil];
    GHAssertEqualStrings(c.name, @"CS161", @"course should be CS161");
    GHAssertEquals(c.position, 2, @"CS161 position should be 2");
}

/*
- (void)testBar {
    // Another test
    //GHTestLog(@"I can log to the GHUnit test console: %@", a);

    // Assert a is not NULL, with no custom error description
    //GHAssertNotNULL(a, nil);
    
    // Assert equal objects, add custom error description
    //GHAssertEqualObjects(a, b, @"Foo should be equal to: %@. Something bad happened", bar);
    
}
*/

@end
