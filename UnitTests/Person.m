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

+ (void)initialize
{
    static dispatch_once_t pred;    
    dispatch_once(&pred, ^{ 
        table = @"person";
        
        databaseTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:DASQLint], @"pkey",
                         [NSNumber numberWithInt:DASQLint], @"position",
                         [NSNumber numberWithInt:DASQLdouble], @"doubleValue",
                         [NSNumber numberWithInt:DASQLstring], @"firstName",
                         [NSNumber numberWithInt:DASQLstring], @"lastName",
                         [NSNumber numberWithInt:DASQLdate], @"aDate",
                         nil];
    });
}

+ (NSString*)databaseTable
{
    return table;
}

+ (NSDictionary*)databaseTypes
{
    return databaseTypes;
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
