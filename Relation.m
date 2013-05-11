//
//  Relation.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Relation.h"

@implementation Member

@synthesize type, ref, role,member;

@end


@implementation Relation

@synthesize members;

-(id) init {
	if (self!=[super init]) {
		return nil;
	}
	members = [[NSMutableArray alloc] initWithCapacity:0];
	return self;
}

-(NSString *)tableName
{
    return @"relations";
}
-(NSString *)tagsTableName
{
    return @"relations_tags";
}


@end
