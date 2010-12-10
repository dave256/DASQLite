//
//  FMDatabase+Memory.h
//  DASQLite
//
//  Created by David Reed on 12/10/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//


#import "FMDatabase.h"

@interface FMDatabase(Memory)

- (id)initWithMemory;
- (BOOL)copyDatabaseToMemory:(NSString*)filename;
- (BOOL)saveMemoryDatabaseToFile:(NSString*)filename;

@end
