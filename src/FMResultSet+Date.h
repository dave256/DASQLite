//
//  FMResultSet+Date.h
//  DASQLite
//
//  Created by David Reed on 11/11/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import "FMResultSet.h"

@interface FMResultSet(Dates)

- (void) kvcMagic:(id)object dates:(NSArray*)dateCols;


@end
