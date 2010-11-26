//
//  Course.h
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import "DASQLiteRow.h"


@interface Course : DASQLiteRow {
    
    NSString *name;
    int position;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic) int position;

@end
