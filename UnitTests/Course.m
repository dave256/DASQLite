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

+ (void)initialize
{
    static dispatch_once_t pred;    
    dispatch_once(&pred, ^{ 
        table = @"course";
        
        databaseTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
                         [NSNumber numberWithInt:DASQLint], @"pkey",
                         [NSNumber numberWithInt:DASQLint], @"position",
                         [NSNumber numberWithInt:DASQLstring], @"name",
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
    return [NSString stringWithFormat:@"%@ %d %d", name, position, pkey];
}

-(void) dealloc {
    [name release];
    [super dealloc];
}

@end
