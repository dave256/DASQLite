//
//  Person.m
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import "Person.h"


@implementation Person

@synthesize firstName;
@synthesize lastName;
@synthesize aDate;
@synthesize doubleValue;
@synthesize position;

static NSString *table;
static NSDictionary *databaseTypes;
static NSArray *dateCols;
static int pkeyCounter;

+ (void)initialize
{
    static dispatch_once_t pred;    
    dispatch_once(&pred, ^{ 
        pkeyCounter = 0;
        table = @"person";
        
        databaseTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
                         @"int", @"pkey",
                         @"int", @"position",
                         @"double", @"doubleValue",
                         @"NSString", @"firstName",
                         @"NSString", @"lastName",
                         @"NSDate", @"aDate",
                         nil];
        dateCols = [[NSArray alloc] initWithObjects:@"aDate", nil];
    });
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
    return [NSString stringWithFormat:@"%@ %@ %@ %d %lf %d", firstName, lastName, aDate, position, doubleValue, pkey];
}

-(void) dealloc {
    [firstName release];
    [lastName release];
    [aDate release];
    [super dealloc];
}



@end
