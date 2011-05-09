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

- (void) valuesFromResultSet:(FMResultSet*)rs;

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
            int columnType = [[colTypes objectForKey:col] intValue];
            NSString *nameType = nil;
            switch (columnType) {
                case DASQLint:
                    nameType = [[NSString alloc] initWithFormat:@", %@ integer", col];
                    break;
                
                case DASQLdouble:
                    nameType = [[NSString alloc] initWithFormat:@", %@ real", col];
                    break;
                    
                case DASQLstring:
                    nameType = [[NSString alloc] initWithFormat:@", %@ text", col];
                    break;
                    
                case DASQLdate:
                    nameType = [[NSString alloc] initWithFormat:@", %@ real", col];
                    break;
                default:
                    break;
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
        [obj valuesFromResultSet:rs];
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
#pragma mark private methods

- (void) valuesFromResultSet:(FMResultSet*)rs {
 
    NSDictionary *colTypes = [[self class] databaseTypes];
    int i;
    double d;
    NSDate *date;
    
    int numCols = [rs columnCount];
    for (i=0; i<numCols; ++i) {
        NSString *colName = [rs columnNameForIndex:i];
        int columnType = [[colTypes objectForKey:colName] intValue];
        switch (columnType) {
            case DASQLint:
            case DASQLdouble:
            case DASQLstring:
                [self setValue:[rs objectForColumnIndex:i] forKey:colName];
                break;
            case DASQLdate:
                d = [rs doubleForColumnIndex:i];
                date = [[NSDate alloc] initWithTimeIntervalSince1970:d];
                [self setValue:date forKey:colName];
                [date release];
            default:
                break;
        }
    }
}


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
    while ([rs next]) {
        DASQLiteRow *obj = [[[self class] alloc] init];
        [obj valuesFromResultSet:rs];
        [items addObject:obj];
        [obj release];
    }
    return [items autorelease];
}

+ (NSMutableDictionary*)database:(FMDatabase*)db dictionaryOfObjectsforCommand:(NSString*)sqlcmd {
    
    NSMutableDictionary *items = [[NSMutableDictionary alloc] init];
    DLog(@"%@", sqlcmd);
    FMResultSet *rs = [db executeQuery:sqlcmd];
    while ([rs next]) {
        DASQLiteRow *obj = [[[self class] alloc] init];
        [obj valuesFromResultSet:rs];
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
        NSDate *date;
        NSDictionary *colTypes = [[self class] databaseTypes];
        for (NSString *colName in colTypes) {
            int columnType = [[colTypes objectForKey:colName] intValue];
            switch (columnType) {
                // numeric types should automatically be set to zero
                case DASQLint:
                case DASQLdouble:
                    break;
                case DASQLstring:
                    [self setValue:@"" forKey:colName];
                    break;
                case DASQLdate:
                    date = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
                    [self setValue:date forKey:colName];
                    [date release];
                default:
                    break;
            }
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

    for (NSString *colName in colTypes) {
        if (! ([colName isEqualToString:@"pkey"])) {
            NSString *stringVal;
            NSDate *dateVal;
            id s = nil;
            [colArray addObject:colName];
            [valuesArray addObject:@"?"];
            int columnType = [[colTypes objectForKey:colName] intValue];
            
            switch (columnType) {
                case DASQLint:
                case DASQLdouble:
                    s = [self valueForKey:colName];
                    [s retain];
                    break;
                case DASQLstring:
                    stringVal = [self valueForKey:colName];
                    if ([stringVal isKindOfClass:[NSAttributedString class]]) {
                        stringVal = [(NSAttributedString*)stringVal string];
                    }
                    if (stringVal) {
                        s = [[NSString alloc] initWithString:stringVal];
                    }
                    else {
                        s = [[NSString alloc] initWithFormat:@""];
                    }
                    break;
                case DASQLdate:
                    dateVal = [self valueForKey:colName];
                    s = [[NSNumber alloc] initWithDouble:[dateVal timeIntervalSince1970]];
                default:
                    break;
            }
            if (s) {
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
    NSUInteger numCols = [colTypes count];
    NSMutableArray *dataArray = [[NSMutableArray alloc] initWithCapacity:numCols];
    NSMutableArray *cmdArray = [[NSMutableArray alloc] initWithCapacity:numCols*2 + 5];
    [cmdArray addObject:@"update"];
    [cmdArray addObject:[[self class] databaseTable]];
    [cmdArray addObject:@"set"];

    for (NSString *colName in colTypes) {
        id s = nil;
        int columnType = [[colTypes objectForKey:colName] intValue];
        NSString *colValue = [[NSString alloc] initWithFormat:@"%@=?", colName];
        [cmdArray addObject:colValue];
        [colValue release];
        
        NSString *stringVal;
        NSDate *dateVal;
        switch (columnType) {
            case DASQLint:
            case DASQLdouble:
                s = [self valueForKey:colName];
                [s retain];
                break;
            case DASQLstring:
                stringVal = [self valueForKey:colName];
                if ([stringVal isKindOfClass:[NSAttributedString class]]) {
                    stringVal = [(NSAttributedString*)stringVal string];
                }
                if (stringVal) {
                    s = [[NSString alloc] initWithString:stringVal];
                }
                else {
                    s = [[NSString alloc] initWithFormat:@""];
                }
                break;
            case DASQLdate:
                dateVal = [self valueForKey:colName];
                s = [[NSNumber alloc] initWithDouble:[dateVal timeIntervalSince1970]];
            default:
                break;
        }
        
        [dataArray addObject:s];
        [s release];
        [cmdArray addObject:@","];
    }

    [cmdArray removeLastObject];
    [cmdArray addObject:[NSString stringWithFormat:@"where pkey=%@", [self valueForKey:@"pkey"]]];
    NSString *sqlcmd = [cmdArray componentsJoinedByString:@" "];
    DLog(@"%@", sqlcmd);
    [cmdArray release];
    BOOL result =[db executeUpdate:sqlcmd withArgumentsInArray:dataArray];
    [dataArray release];
    return result;
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

