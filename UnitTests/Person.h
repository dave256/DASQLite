//
//  Person.h
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import "DASQLiteRow.h"

@interface Person : DASQLiteRow {

    int pkey;
    NSString *firstName;
    NSString *lastName;
    NSDate *aDate;
    double doubleValue;
    int position;
}

@property (nonatomic) int pkey;
@property (nonatomic, retain) NSString *firstName;    
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSDate *aDate;
@property (nonatomic) double doubleValue;
@property (nonatomic) int position;
    

@end
