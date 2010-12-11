//
//  Course.m
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import "Course.h"

@implementation Course

@synthesize name;
@synthesize position;

static NSString *table;
static NSDictionary *databaseTypes;
static NSArray *dateCols;
static int pkeyCounter;

+ (void)initialize
{
    pkeyCounter = 0;
    table = @"course";
    
    databaseTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
                     @"int", @"pkey",
                     @"int", @"position",
                     @"NSString", @"name",
                     nil];
    dateCols = nil;
}

+ (int)getNextPkey {
    dispatch_sync([[self class] pkeyDQ], ^{
        pkeyCounter++;
    });
    return pkeyCounter;
}

+ (NSString*)databaseTable
{
    return table;
}

+ (NSDictionary*)databaseTypes
{
    return databaseTypes;
}

+ (NSArray*)dateCols
{
    return dateCols;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %d %d", name, position, pkey];
}

-(void) dealloc {
    [name release];
    [super dealloc];
}

@end
