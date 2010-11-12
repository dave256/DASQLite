//
//  FMResultSet+Date.m
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import "FMDatabase.h"
#import "unistd.h"
#import "FMResultSet+Date.h"


@implementation FMResultSet(Date)

- (void) kvcMagic:(id)object dates:(NSArray*)dateCols {
    
    int columnCount = sqlite3_column_count(statement.statement);
    
    int columnIdx = 0;
    for (columnIdx = 0; columnIdx < columnCount; columnIdx++) {
        
        const char *c = (const char *)sqlite3_column_text(statement.statement, columnIdx);
        
        // check for a null row
        if (c) {
            NSString *s = [NSString stringWithUTF8String:c];            
            [object setValue:s forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement.statement, columnIdx)]];
        }
    }
    for (NSString *col in dateCols) {
        [object setValue:[NSDate dateWithTimeIntervalSince1970:[self doubleForColumn:col]] forKey:col];
    }
}

@end
