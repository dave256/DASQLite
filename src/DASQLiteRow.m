//
//  DASQLiteRow.m
//  DASQLite
//
//  Created by David Reed on 11/9/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import "FMDatabase.h"
#import "FMResultSet+Date.h"
#import "DASQLiteRow.h"

#pragma mark -------------------- private methods --------------------

@interface DASQLiteRow()

+ (NSString*)allWhere:(NSString*)whereClause orderBy:(NSString *)orderByClause;
+ (NSMutableArray*)database:(FMDatabase*)db arrayOfObjectsforCommand:(NSString*)sqlcmd;
+ (NSDictionary*)database:(FMDatabase*)db dictionaryOfObjectsforCommand:(NSString*)sqlcmd;

@end

#pragma mark -------------------- implementation --------------------

@implementation DASQLiteRow

@synthesize pkey;

#pragma mark -------------------- class methods to override --------------------

+ (NSString*)databaseTable {
    [NSException raise:NSInternalInconsistencyException format:@"You must override databaseTable in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

+ (NSDictionary*)databaseTypes {
     [NSException raise:NSInternalInconsistencyException format:@"You must override databaseTypes in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

+ (NSArray*) dateCols {
    [NSException raise:NSInternalInconsistencyException format:@"You must override dateCols in a subclass", NSStringFromSelector(_cmd)];
    return nil;
}

#pragma mark -------------------- class methods --------------------

+ (BOOL)createTable:(FMDatabase*)db {
    
    NSDictionary *colTypes = [[self class] databaseTypes];
    NSMutableArray *cmdArray = [[NSMutableArray alloc] initWithCapacity:[colTypes count] + 5];
    NSString *create = [[NSString alloc] initWithFormat:@"create table %@ (pkey integer primary key", [[self class] databaseTable]];
    [cmdArray addObject:create];
    [create release];
    for (NSString *col in colTypes) {
        if (! ([col isEqualToString:@"pkey"])) {
            NSString *ctype = [colTypes objectForKey:col];
            NSString *nameType = nil;
            if ([ctype isEqualToString:@"NSString"]) {
                nameType = [[NSString alloc] initWithFormat:@", %@ text", col]; 
            }
            else if ([ctype isEqualToString:@"NSDate"]) {
                nameType = [[NSString alloc] initWithFormat:@", %@ real", col];
            }
            else if ([ctype isEqualToString:@"int"]) {
                nameType = [[NSString alloc] initWithFormat:@", %@ integer", col];
            }
            else if ([ctype isEqualToString:@"double"]) {
                nameType = [[NSString alloc] initWithFormat:@", %@ real", col];
            }
            [cmdArray addObject:nameType];
            [nameType release];
        }
    }
    [cmdArray addObject:@")"];
    NSString *sqlcmd = [cmdArray componentsJoinedByString:@" "];
    [cmdArray release];
    
    DLog(@"%@", sqlcmd);
    [db executeUpdate:sqlcmd];
    return YES;
}

+ (BOOL)createTableWithTransaction:(FMDatabase *)db {
    [db beginTransaction];
    BOOL ok = [self createTable:db];
    [db commit];
    return ok;
}

+ (id)database:(FMDatabase*)db selectOneWhere:(NSString*)whereClause orderBy:(NSString *)orderByClause {

    NSString *where;
    NSString *order;
    NSString *sqlcmd;

    if (whereClause) {
        where = [[NSString alloc] initWithFormat:@"%@", whereClause];
    }
    else {
        where = [[NSString alloc] initWithFormat:@""];
    }
    if (orderByClause) {
        order = [[NSString alloc] initWithFormat:@"%@", orderByClause];
    }
    else {
        order = [[NSString alloc] initWithFormat:@""];
    }
    sqlcmd = [NSString stringWithFormat:@"select * from %@ %@ %@ limit 1", [[self class] databaseTable], where, order];
    [where release];
    [order release];
    DLog(@"%@", sqlcmd);
    FMResultSet *rs = [db executeQuery:sqlcmd];
    DASQLiteRow *obj = nil;
    BOOL exists = [rs next];
    if (exists) {
        obj = [[[self class] alloc] init];
        [rs kvcMagic:obj dates:[[self class] dateCols]];        
        while ([rs next]);        
    }
    return [obj autorelease];
}

+ (NSMutableArray*)database:(FMDatabase*)db select:(NSString*)sqlcmd {
    return [[self class] database:db arrayOfObjectsforCommand:sqlcmd];
}

+ (NSMutableArray*)database:(FMDatabase*)db selectAllWhere:(NSString*)whereClause orderBy:(NSString *)orderByClause {
    NSString *sqlcmd = [[self class] allWhere:whereClause orderBy:orderByClause];
    return [[self class] database:db arrayOfObjectsforCommand:sqlcmd];
}

+ (NSDictionary*)database:(FMDatabase*)db dictionarySelectAllWhere:(NSString*)whereClause {
    NSString *sqlcmd = [[self class] allWhere:whereClause orderBy:nil];
    return [[self class] database:db dictionaryOfObjectsforCommand:sqlcmd];
}

#pragma mark -------------------- private class methods --------------------

+ (NSString*)allWhere:(NSString*)whereClause orderBy:(NSString *)orderByClause {
    NSString *where;
    NSString *order;
    NSString *sqlcmd;
    
    if (whereClause) {
        where = [[NSString alloc] initWithFormat:@"%@", whereClause];
    }
    else {
        where = [[NSString alloc] initWithFormat:@""];
    }
    if (orderByClause) {
        order = [[NSString alloc] initWithFormat:@"%@", orderByClause];
    }
    else {
        order = [[NSString alloc] initWithFormat:@""];
    }
    sqlcmd = [NSString stringWithFormat:@"select * from %@ %@ %@", [[self class] databaseTable], where, order];
    [where release];
    [order release];
    return sqlcmd;
}

+ (NSMutableArray*)database:(FMDatabase*)db arrayOfObjectsforCommand:(NSString*)sqlcmd {

    NSMutableArray *items = [[NSMutableArray alloc] init];
    DLog(@"%@", sqlcmd);
    FMResultSet *rs = [db executeQuery:sqlcmd];
    NSArray *dateCols = [[self class] dateCols];
    while ([rs next]) {
        DASQLiteRow *obj = [[[self class] alloc] init];
        [rs kvcMagic:obj dates:dateCols];
        [items addObject:obj];
        [obj release];
    }
    return [items autorelease];
}

+ (NSDictionary*)database:(FMDatabase*)db dictionaryOfObjectsforCommand:(NSString*)sqlcmd {
    
    NSMutableDictionary *items = [[NSMutableDictionary alloc] init];
    DLog(@"%@", sqlcmd);
    FMResultSet *rs = [db executeQuery:sqlcmd];
    NSArray *dateCols = [[self class] dateCols];
    while ([rs next]) {
        DASQLiteRow *obj = [[[self class] alloc] init];
        [rs kvcMagic:obj dates:dateCols];
        [items setObject:obj forKey:[NSNumber numberWithInt:obj.pkey]];
        [obj release];
    }
    return [items autorelease];
}

#pragma mark -------------------- instance methods --------------------

- (BOOL)insert:(FMDatabase*)db {
    NSDictionary *colTypes = [[self class] databaseTypes];
    
    NSMutableArray *cmdArray = [[NSMutableArray alloc] init];
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    [cmdArray addObject:@"insert into"];
    [cmdArray addObject:[[self class] databaseTable]];
    [cmdArray addObject:@"("];
    [dataArray addObject:@"("];
    for (NSString *col in colTypes) {
        if (! ([col isEqualToString:@"pkey"])) {
            NSString *s;
            NSString *ctype = [colTypes objectForKey:col];
            if ([self valueForKey:col]) {
                
                [cmdArray addObject:col];
                [cmdArray addObject:@","];
                
                if ([ctype isEqualToString:@"NSString"]) {
                    NSString *val = [self valueForKey:col];
                    s = [[NSString alloc] initWithFormat:@"'%@'", [val stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
                }
                else if ([ctype isEqualToString:@"NSDate"]) {
                    NSDate *val = [self valueForKey:col];
                    s = [[NSString alloc] initWithFormat:@"%lf", [val timeIntervalSince1970]];
                }
                // int or double
                else {
                    s = [[NSString alloc] initWithFormat:@"%@", [self valueForKey:col]];
                }
                
                [dataArray addObject:s];
                [s release];
                [dataArray addObject:@","];
            }
        }
    }
    
    [cmdArray removeLastObject];
    [dataArray removeLastObject];
    
    [cmdArray addObject:@") values"];
    [dataArray addObject:@")"];
    
    [cmdArray addObjectsFromArray:dataArray];
    
    DLog(@"%@", [cmdArray componentsJoinedByString:@" "]);
    
    [db executeUpdate:[cmdArray componentsJoinedByString:@" "]];
    [cmdArray release];
    [dataArray release];
    
    FMResultSet *rs = [db executeQuery:@"SELECT last_insert_rowid() as pkey"];
    [rs next];
    [rs kvcMagic:self];
    while ([rs next]);
    
    return YES;
}

- (BOOL)insertWithTransaction:(FMDatabase*)db {
    [db beginTransaction];
    BOOL ok = [self insert:db];
    [db commit];
    return ok;
}

- (BOOL)update:(FMDatabase *)db {
    NSDictionary *colTypes = [[self class] databaseTypes];

    NSMutableArray *cmdArray = [[NSMutableArray alloc] init];
    [cmdArray addObject:@"update"];
    [cmdArray addObject:[[self class] databaseTable]];
    [cmdArray addObject:@"set"];

    for (NSString *col in colTypes) {
        NSString *s;
        NSString *ctype = [colTypes objectForKey:col];
        if ([self valueForKey:col]) {

            if ([ctype isEqualToString:@"NSString"]) {
                NSString *val = [self valueForKey:col];
                s = [[NSString alloc] initWithFormat:@"%@='%@'",
                     col, [val stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
            }
            else if ([ctype isEqualToString:@"NSDate"]) {
                NSDate *val = [self valueForKey:col];
                s = [[NSString alloc] initWithFormat:@"%@=%lf",
                     col, [val timeIntervalSince1970]];
            }
            // int or double
            else {
                s = [[NSString alloc] initWithFormat:@"%@=%@",
                     col, [self valueForKey:col]];
            }

            [cmdArray addObject:s];
            [s release];
            [cmdArray addObject:@","];
        }
    }

    [cmdArray removeLastObject];
    [cmdArray addObject:[NSString stringWithFormat:@"where pkey=%@", [self valueForKey:@"pkey"]]];
    DLog(@"%@", [cmdArray componentsJoinedByString:@" "]);
    [db executeUpdate:[cmdArray componentsJoinedByString:@" "]];
    [cmdArray release];
    return YES;
}

- (BOOL)updateWithTransaction:(FMDatabase*)db {
    [db beginTransaction];
    BOOL ok = [self update:db];
    [db commit];
    return ok;
}

- (BOOL) delete:(FMDatabase*)db {
    NSString *sqlcmd = [[NSString alloc] initWithFormat:@"delete from %@ where pkey=%@", [[self class] databaseTable], [self valueForKey:@"pkey"]];
    DLog(@"%@", sqlcmd);
    [db executeUpdate:sqlcmd];
    [sqlcmd release];
    return YES;
}

- (BOOL)deleteWithTransaction:(FMDatabase*)db {
    [db beginTransaction];
    BOOL ok = [self delete:db];
    [db commit];
    return ok;
}

- (void)dealloc {
    [super dealloc];
}

@end

