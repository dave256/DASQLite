//
//  Person.m
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import "Person.h"


@implementation Person

@synthesize pkey;
@synthesize firstName;
@synthesize lastName;
@synthesize aDate;
@synthesize position;

static NSString *table;
static NSDictionary *databaseTypes;
static NSArray *dateCols;

+ (void)initialize
{
    table = @"person";
    
    databaseTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
                     @"int", @"pkey",
                     @"int", @"position",
                     @"NSString", @"firstName",
                     @"NSString", @"lastName",
                     @"NSDate", @"aDate",
                     nil];
    dateCols = [[NSArray alloc] initWithObjects:@"aDate", nil];
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
    return [NSString stringWithFormat:@"%@ %@ %@ %d %d", firstName, lastName, aDate, position, pkey];
}

-(void) dealloc {
    [firstName release];
    [lastName release];
    [aDate release];
    [super dealloc];
}



@end
