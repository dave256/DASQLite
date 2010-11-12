//
//  Course.m
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import "Course.h"

@implementation Course

@synthesize pkey;
@synthesize name;
@synthesize position;

static NSString *table;
static NSDictionary *databaseTypes;
static NSArray *dateCols;

+ (void)initialize
{
    table = @"course";
    
    databaseTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
                     @"int", @"pkey",
                     @"int", @"position",
                     @"NSString", @"name",
                     nil];
    dateCols = nil;
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
