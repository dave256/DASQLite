//
//  TestDASQLite.m
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//



#import <GHUnit/GHUnit.h>

#import "FMDatabase.h"
#import "FMDatabase+Memory.h"
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
    // remove in case file exists
    system("/bin/rm -f /tmp/testdasqlite.db");
    // creates new file if does not exist
    db = [[FMDatabase alloc] initWithPath:@"/tmp/testdasqlite.db"];
    [db setLogsErrors:YES];
    GHAssertEquals([db open], YES, @"failed to open database");
    
    [db beginTransaction];
    [Person createTable:db];
    //GHAssertEquals([db executeUpdate:@"create table person (pkey integer primary key, lastName text, firstName text, position integer, aDate real)"], YES, nil);

    Person *p;
    
    p = [[Person alloc] init];
    p.firstName = @"Dave";
    p.lastName = @"Reed";
    p.position = 2;
    p.doubleValue = 0.5;
    p.aDate = [NSDate date];
    [p insert:db];
    [p release];
    
    p = [[Person alloc] init];
    p.firstName = @"John";
    p.lastName = @"Stroeh";
    p.position = 3;
    p.doubleValue = 1.5;
    p.aDate = [NSDate date];
    [p insert:db];
    [p release];
    
    p = [[Person alloc] init];
    p.firstName = @"Matt";
    p.lastName = @"Anderson";
    p.position = 1;
    p.doubleValue = 2.5;
    p.aDate = [NSDate date];
    [p insert:db];
    [p release];
    
   [db commit];
    
    [Course createTable:db];
    //GHAssertEquals([db executeUpdate:@"create table course (pkey integer primary key, name text, position integer)"], YES, nil);
    
    Course *c;
    
    c = [[Course alloc] init];
    c.position = 2;
    c.name = @"CS161";
    [c insert:db];
    [c release];
    
    c = [[Course alloc] init];
    c.position = 1;
    c.name = @"CS160";
    [c insert:db];
    [c release];
    
    
    GHAssertEquals([db executeUpdate:@"insert into course (name, position) values ('CS161', 2)"], YES, nil);
    GHAssertEquals([db executeUpdate:@"insert into course (name, position) values ('CS160', 1)"], YES, nil);

    //GHAssertEquals([db commit], YES, nil);
}

- (void)tearDown {
    // Run after each test method
    [db close];
    [db release];
    // comment out if want to examine database afterwards
    system("/bin/rm -f /tmp/testdasqlite.db");
}

#pragma mark -------------------- tests --------------------

- (void)testInit {
    Person *p = [[Person alloc] init];
    GHAssertNotNil(p.firstName, nil);
    GHAssertNotNil(p.lastName, nil);
    GHAssertEqualStrings(p.firstName, @"", nil);
    GHAssertEqualStrings(p.lastName, @"", nil);
    GHAssertEquals(p.position, 0, nil);
    GHAssertEquals(p.pkey, 0, nil);
}

- (void)testMemory {
    FMDatabase *memoryDB = [[FMDatabase alloc] initWithMemory];
    [memoryDB setLogsErrors:YES];
    [memoryDB open];
    [memoryDB loadDatabaseIntoMemory:@"/tmp/testdasqlite.db"];
    [memoryDB beginTransaction];
    [memoryDB executeUpdate:@"insert into person (lastName, firstName, position, aDate, doubleValue) values ('Stanton', 'Chris', 1, 1289515894.9236939, 2.5)"];
    [memoryDB commit];
    
    Person *pFail = [Person database:db selectOneWhere:@"where lastName='Stanton'" orderBy:nil];
    Person *pOk = [Person database:memoryDB selectOneWhere:@"where lastName='Stanton'" orderBy:nil];
    
    GHAssertNil(pFail, @"Chris Stanton should not be in file database");
    GHAssertEqualStrings(pOk.firstName, @"Chris", @"memory database should contain Chris Stanton");
        
    //[db close];
    [memoryDB saveMemoryDatabaseToFile:@"/tmp/testdasqlite.db"];
    [memoryDB release];
    //[db open];

    Person *pOk2 = [Person database:db selectOneWhere:@"where lastName='Reed'" orderBy:nil];
    GHAssertEqualStrings(pOk2.firstName, @"Dave", @"after reopening, it should contain Dave Reed");
    Person *pOk3 = [Person database:db selectOneWhere:@"where lastName='Stanton'" orderBy:nil];
    GHAssertEqualStrings(pOk3.firstName, @"Chris", @"after saving, it should contain Chris Stanton");
    
}

- (void)testSelectAllWhereForAll {
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    for (Person *p in people) {
        //GHTestLog(@"%@", p);
    }
    GHAssertEquals([people count], (NSUInteger)3, nil);
}

- (void)testSelectAllWhere {
    NSArray *people;
    
    people = [Person database:db selectAllWhere:@"where position<=2" orderBy:@"order by position"];
    /*
    for (Person *p in people) {
        GHTestLog(@"%@", p);
    }
     */
    GHAssertEquals([people count], (NSUInteger)2, nil);
}

- (void)testSelectOne {
    Person *p = [Person database:db selectOneWhere:@"where lastName='Reed'" orderBy:nil];
    GHAssertEqualStrings(p.firstName, @"Dave", nil);
    GHAssertEqualStrings(p.lastName, @"Reed", nil);
}

- (void)testInsert {
    Person *p = [[Person alloc] init];
    p.firstName = @"John";
    p.lastName = @"Doe";
    for (int i=4; i<1004; ++i) {
        p.pkey = 0;
        p.position = i;
        p.doubleValue = i + 0.5;
        [p insertWithTransaction:db];
        GHAssertEquals(p.pkey, i, @"in theory this could be wrong if pkeys not in order");
    }
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1003, nil);

    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1001, nil);
}

- (void)testInsertUpdateEmptyString {
    [db executeUpdate:@"delete from person"];
    Person *p = [[Person alloc] init];
    p.firstName = @"";
    p.lastName = @"Reed";
    [p insert:db];

    Person *pr;
    pr = [Person database:db selectOneWhere:@"where lastName='Reed'" orderBy:nil];
    GHAssertEqualStrings(pr.firstName, @"", nil);
    GHAssertEqualStrings(pr.lastName, @"Reed", nil);
    
    p.firstName = @"Dave";
    p.lastName = @"";
    [p update:db];
    pr = [Person database:db selectOneWhere:@"where firstName='Dave'" orderBy:nil];
    GHAssertEqualStrings(pr.firstName, @"Dave", nil);
    GHAssertEqualStrings(pr.lastName, @"", nil);
}

- (void)testInsertNoTransaction {
    Person *p = [[Person alloc] init];
    p.firstName = @"John";
    p.lastName = @"Doe";
    [db beginTransaction];
    for (int i=4; i<1004; ++i) {
        p.pkey = 0;
        p.position = i;
        p.doubleValue = i + 0.5;
        [p insert:db];
    }
    [db commit];
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1003, nil);
    
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1001, nil);
}

- (void)testUpdate {
    Person *p1 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    p1.lastName = @"Lewis";
    [p1 updateWithTransaction:db];
    p1.position = 100;
    [p1 updateWithTransaction:db];
    NSArray *people = [Person database:db selectAllWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1, nil);
    Person *p2 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEqualStrings(p2.firstName, @"Matt", nil);
    GHAssertEqualStrings(p2.lastName, @"Lewis", nil);
    GHAssertEquals(p2.position, 100, nil);
    
    p2.lastName = @"Anderson";
    p2.position = 1;
    NSDate *now = [NSDate date];
    p2.aDate = now;
    p2.pkey = 0;
    [p2 insert:db];
    
    people = [Person database:db selectAllWhere:@"where firstName='Matt'" orderBy:@"order by lastName, firstName"];
    GHAssertEquals([people count], (NSUInteger)2, nil);
    p1 = [people objectAtIndex:0];
    p2 = [people objectAtIndex:1];
    GHAssertEqualStrings(p1.firstName, @"Matt", nil);
    GHAssertEqualStrings(p1.lastName, @"Anderson", nil);
    GHAssertEquals(p1.position, 1, nil);
    GHAssertEqualStrings([p1.aDate description], [now description], nil);
    
    
    GHAssertEqualStrings(p2.firstName, @"Matt", nil);
    GHAssertEqualStrings(p2.lastName, @"Lewis", nil);
    GHAssertEquals(p2.position, 100, nil);
}

- (void)testUpdateNoTransaction {
    Person *p1 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    p1.lastName = @"Lewis";
    [db beginTransaction];
    [p1 update:db];
    p1.position = 100;
    [p1 update:db];
    NSArray *people = [Person database:db selectAllWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1, nil);
    Person *p2 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEqualStrings(p2.firstName, @"Matt", nil);
    GHAssertEqualStrings(p2.lastName, @"Lewis", nil);
    GHAssertEquals(p2.position, 100, nil);
    
    p2.lastName = @"Anderson";
    p2.position = 1;
    NSDate *now = [NSDate date];
    p2.aDate = now;
    p2.pkey = 0;
    [p2 insert:db];
    [db commit];
    
    people = [Person database:db selectAllWhere:@"where firstName='Matt'" orderBy:@"order by lastName, firstName"];
    GHAssertEquals([people count], (NSUInteger)2, nil);
    p1 = [people objectAtIndex:0];
    p2 = [people objectAtIndex:1];
    GHAssertEqualStrings(p1.firstName, @"Matt", nil);
    GHAssertEqualStrings(p1.lastName, @"Anderson", nil);
    GHAssertEquals(p1.position, 1, @"position");
    GHAssertEqualStrings([p1.aDate description], [now description], nil);
    
    GHAssertEqualStrings(p2.firstName, @"Matt", nil);
    GHAssertEqualStrings(p2.lastName, @"Lewis", nil);
    GHAssertEquals(p2.position, 100, nil);
}

- (void)testDelete {
    Person *p = [[Person alloc] init];
    p.firstName = @"John";
    p.lastName = @"Doe";
    [db beginTransaction];
    for (int i=4; i<1004; ++i) {
        p.position = i;
        p.pkey = 0;
        [p insert:db];
    }
    [db commit];
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1003, nil);
    
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1001, nil);
    
    for (Person *p in people) {
        [p delete:db];
    }
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)0, nil);
    people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)2, nil);
}

- (void)testDeleteNoTransaction {
    Person *p = [[Person alloc] init];
    p.firstName = @"John";
    p.lastName = @"Doe";
    [db beginTransaction];
    for (int i=4; i<1004; ++i) {
        p.position = i;
        p.pkey = 0;
        [p insert:db];
    }
    [db commit];
    NSArray *people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1003, nil);
    
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1001, nil);
    
    [db beginTransaction];
    for (Person *p in people) {
        [p delete:db];
    }
    [db commit];
    people = [Person database:db selectAllWhere:@"where firstName='John'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)0, nil);
    people = [Person database:db selectAllWhere:nil orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)2, nil);
}

-(void)testSingleQuote {
    Person *p1 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    p1.lastName = @"D'Matteo";
    [p1 update:db];
    p1 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEqualStrings(p1.lastName, @"D'Matteo", nil);
    p1.firstName = @"Tim";
    p1.pkey = 0;
    [p1 insert:db];
    NSArray *people = [Person database:db selectAllWhere:@"where lastName='D''Matteo'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)2, nil);
}

-(void)testDoubleQuote {
    Person *p1 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    p1.lastName = @"D\"Matteo";
    [p1 update:db];
    p1 = [Person database:db selectOneWhere:@"where firstName='Matt'" orderBy:nil];
    GHAssertEqualStrings(p1.lastName, @"D\"Matteo", nil);
    p1.firstName = @"Tim";
    p1.pkey = 0;
    [p1 insert:db];
    NSArray *people = [Person database:db selectAllWhere:@"where lastName='D\"Matteo'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)2, nil);
}

- (void)testQuestion {
    Person *p1 = [[Person alloc] init];
    p1.firstName = @"Dave?";
    p1.lastName = @"Reed";
    [p1 insert:db];
    NSArray *people = [Person database:db selectAllWhere:@"where lastName='Reed'" orderBy:@"order by firstName"];
    GHAssertEquals([people count], (NSUInteger)2, nil);
    Person *p2;
    p2 = [people objectAtIndex:0];
    GHAssertEqualStrings(p2.firstName, @"Dave", nil);
    p2 = [people objectAtIndex:1];
    GHAssertEqualStrings(p2.firstName, @"Dave?", nil);
    
    p1.lastName = @"Re?ed";
    [p1 update:db];
    people = [Person database:db selectAllWhere:@"where lastName='Re?ed'" orderBy:nil];
    GHAssertEquals([people count], (NSUInteger)1, nil);   
}

- (void)testSecondType {
    Course *c;
    c = [Course database:db selectOneWhere:nil orderBy:@"order by position"];
    GHAssertEqualStrings(c.name, @"CS160", nil);
    GHAssertEquals(c.position, 1, nil);
    c = [Course database:db selectOneWhere:@"where position=2" orderBy:nil];
    GHAssertEqualStrings(c.name, @"CS161", nil);
    GHAssertEquals(c.position, 2, nil);
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
