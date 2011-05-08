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

#pragma mark -
#pragma mark private methods

@interface DASQLiteRow()

+ (NSString*)allWhere:(NSString*)whereClause orderBy:(NSString *)orderByClause;
+ (NSMutableArray*)database:(FMDatabase*)db arrayOfObjectsforCommand:(NSString*)sqlcmd;
+ (NSMutableDictionary*)database:(FMDatabase*)db dictionaryOfObjectsforCommand:(NSString*)sqlcmd;

@end

#pragma mark -
#pragma mark implementation

@implementation DASQLiteRow

@synthesize pkey;

#pragma mark -
#pragma mark class methods to override

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

#pragma mark -
#pragma mark class methods

+ (BOOL)createTable:(FMDatabase*)db {
    
    NSDictionary *colTypes = [[self class] databaseTypes];
    NSMutableArray *cmdArray = [[NSMutableArray alloc] initWithCapacity:[colTypes count] + 5];
    NSString *create = [[NSString alloc] initWithFormat:@"create table %@ (pkey integer primary key autoincrement", [[self class] databaseTable]];
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
        [rs close];
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

+ (NSMutableDictionary*)database:(FMDatabase*)db dictionarySelectAllWhere:(NSString*)whereClause {
    NSString *sqlcmd = [[self class] allWhere:whereClause orderBy:nil];
    return [[self class] database:db dictionaryOfObjectsforCommand:sqlcmd];
}

#pragma mark -
#pragma mark private class methods

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

+ (NSMutableDictionary*)database:(FMDatabase*)db dictionaryOfObjectsforCommand:(NSString*)sqlcmd {
    
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

#pragma mark -
#pragma mark instance methods

- (id)init {
    self = [super init];
    if (self) {
        NSDictionary *colTypes = [[self class] databaseTypes];
        for (NSString *col in colTypes) {
            NSString *ctype = [colTypes objectForKey:col];
            if ([ctype isEqualToString:@"NSString"]) {
                [self setValue:@"" forKey:col];
            }
            else if ([ctype isEqualToString:@"NSDate"]) {
                [self setValue:[NSDate date] forKey:col];
            }
            // numeric types should automatically be set to zero
        }
    }
    return self;
}

- (BOOL)insert:(FMDatabase*)db {
    NSDictionary *colTypes = [[self class] databaseTypes];
    NSUInteger numCols = [colTypes count];
    NSMutableArray *colArray = [[NSMutableArray alloc] initWithCapacity:numCols];
    NSMutableArray *valuesArray = [[NSMutableArray alloc] initWithCapacity:numCols];
    NSMutableArray *dataArray = [[NSMutableArray alloc] initWithCapacity:numCols];

    for (NSString *col in colTypes) {
        if (! ([col isEqualToString:@"pkey"])) {
            id s;
            NSString *ctype = [colTypes objectForKey:col];
            if ([self valueForKey:col]) {
                
                [colArray addObject:col];
                [valuesArray addObject:@"?"];
                
                if ([ctype isEqualToString:@"NSString"]) {
                    NSString *val = [self valueForKey:col];
                    if ([val isKindOfClass:[NSAttributedString class]]) {
                        val = [(NSAttributedString*)val string];
                    }
                    if (val) {
                        s = [[NSString alloc] initWithString:val];
                    }
                    else {
                        s = [[NSString alloc] initWithFormat:@""];
                    }
                }
                else if ([ctype isEqualToString:@"NSDate"]) {
                    NSDate *val = [self valueForKey:col];
                    s = [[NSNumber alloc] initWithDouble:[val timeIntervalSince1970]];

                }
                // int or double
                else {
                    s = [self valueForKey:col];
                    [s retain];
                }
                
                [dataArray addObject:s];
                [s release];
            }
        }
    }
    NSString *sqlcmd = [[NSString alloc] initWithFormat:@"insert into %@ (%@) values (%@)", [[self class] databaseTable], [colArray componentsJoinedByString:@","], [valuesArray componentsJoinedByString:@","]];
    BOOL result = [db executeUpdate:sqlcmd withArgumentsInArray:dataArray];
    self.pkey = [db lastInsertRowId];
    [sqlcmd release];
    [colArray release];
    [valuesArray release];
    [dataArray release];
    
    return result;
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
        if ([ctype isEqualToString:@"NSString"]) {
            NSString *val = [self valueForKey:col];
            if (val) {
                if ([val isKindOfClass:[NSAttributedString class]]) {
                    val = [(NSAttributedString*)val string];
                }
                
                s = [[NSString alloc] initWithFormat:@"%@='%@'",
                     col, [val stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
            }
            else {
                s = [[NSString alloc] initWithFormat:@"%@=''", col];
            }
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

