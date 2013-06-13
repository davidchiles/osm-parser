//
//  Way.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Way.h"

@implementation Way

@synthesize nodesIds, nodes, length;

-(id) init {
	if (self!=[super init])
		return nil;
	nodesIds = [[NSMutableArray alloc] init];
	return self;
}

-(BOOL) isFirstNodeId:(int64_t)nodeId {
    if (nodeId != 0 || [nodesIds count]) {
        return [[nodesIds objectAtIndex:0] longLongValue]==nodeId;
    }
    return NO;
}

-(BOOL) isLastNodeId:(int64_t)nodeId {
    if (nodeId != 0 || [nodesIds count]) {
        return [[nodesIds objectAtIndex:[nodesIds count]-1] longLongValue]==nodeId;
    }
    return  NO;
}

-(int64_t) lastNodeId {
	if ([nodesIds count]==0)
		return 0;
	else
		return [[nodesIds objectAtIndex:[nodesIds count]-1] longLongValue];
}

-(int64_t) firstNodeId {
	if ([nodesIds count]==0)
		return 0;
	else
		return [[nodesIds objectAtIndex:0] longLongValue];
}

-(int64_t)getCommonNodeIdWith:(Way*)way {
	int64_t commonNodeId = -1;
	if ([way.nodesIds count]==0 || [self.nodesIds count]==0)
		return commonNodeId;
	int64_t selfStartNode = [[self.nodesIds objectAtIndex:0] longLongValue];
	int64_t selfEndNode = [[self.nodesIds objectAtIndex:[self.nodesIds count]-1]longLongValue];
	int64_t wayStartNode = [[way.nodesIds objectAtIndex:0]intValue];
	int64_t wayEndNode = [[way.nodesIds objectAtIndex:[way.nodesIds count]-1] longLongValue];
	if (selfStartNode==wayStartNode || selfStartNode==wayEndNode)
		commonNodeId= selfStartNode;
	else if (selfEndNode == wayStartNode || selfEndNode == wayEndNode)
		commonNodeId= selfEndNode;
	return commonNodeId;
}

-(NSString*) description {
	return [NSString stringWithFormat:@"Way(%lli)%i nodes", self.elementID, [nodesIds count]];
}

-(NSString *)tableName;
{
    return @"ways";
}
-(NSString *)tagsTableName
{
    return @"ways_tags";
}

@end
