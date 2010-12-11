//
//  DASQLiteRowProtocol.h
//  DASQLite
//
//  Created by David Reed on 11/9/10.
//  Copyright 2010 David M. Reed. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DASQLiteRowProtocol

+ (NSString*)databaseTable;
+ (NSDictionary*)databaseTypes;
+ (NSArray*)dateCols;

@end

