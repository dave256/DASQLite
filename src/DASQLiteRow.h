//
//  DASQLiteRow.h
//  DASQLite
//
//  Created by David Reed on 11/9/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DASQLiteRowProtocol.h"

@class FMDatabase;

// databaseTable and databaseTypes of DASQLiteRowProtocol must be overriden by subclasses of DASQLiteRow

@interface DASQLiteRow : NSObject<DASQLiteRowProtocol> {
    int pkey;
}

@property (nonatomic) int pkey;

// class methods

// returns a subclass of DASQLiteRow
+ (id)database:(FMDatabase*)db selectOneWhere:(NSString*)whereClause orderBy:(NSString *)orderByClause;

+ (NSMutableArray*)database:(FMDatabase*)db select:(NSString*)sqlcmd;
+ (NSMutableArray*)database:(FMDatabase*)db selectAllWhere:(NSString*)whereClause orderBy:(NSString *)orderByClause;
+ (NSDictionary*)database:(FMDatabase*)db dictionarySelectAllWhere:(NSString*)whereClause;

+ (BOOL)createTable:(FMDatabase*)db;
+ (BOOL)createTableNoTransaction:(FMDatabase*)db;

// instance methods

- (BOOL)insert:(FMDatabase*)db;
- (BOOL)insertNoTransaction:(FMDatabase*) db;

- (BOOL)update:(FMDatabase *)db;
- (BOOL)updateNoTransaction:(FMDatabase*)db;

- (BOOL)delete:(FMDatabase*)db;
- (BOOL)deleteNoTransaction:(FMDatabase*)db;

@end

