//
//  OSMParserHandlerDefault.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSMParserHandlerDefault.h"

#import "DDLog.h"
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
static const BOOL OPELogDatabaseErrors = YES;
static const BOOL OPETraceDatabaseTraceExecution = YES;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
static const BOOL OPELogDatabaseErrors = NO;
static const BOOL OPETraceDatabaseTraceExecution = NO;
#endif

@interface OSMParserHandlerDefault (privateAPI)
-(BOOL) checkForWaysFlush;
-(BOOL) checkForNodesFlush;
@end


@implementation OSMParserHandlerDefault

@synthesize ignoreNodes;
@synthesize bufferMaxSize;
@synthesize optimizeOnFinished;

-(id) initWithOutputFilePath:(NSString*)output {
	return [self initWithOutputFilePath:output overrideIfExists:YES];
}

-(id) initWithOutputFilePath:(NSString*)filePath overrideIfExists:(BOOL)override {
	if (self!=[super init])
		return nil;
	self.outputDao=[[OSMDAO alloc] initWithFilePath:filePath overrideIfExists:override];
	nodesBuffer=[[NSMutableArray alloc] init];
	waysBuffer=[[NSMutableArray alloc] init];
	bufferMaxSize=30000;
    optimizeOnFinished = YES;
	return self;
}

#pragma mark -
#pragma mark Parser delegate
-(void) didStartParsingNodes {
	DDLogInfo(@"[NOW PARSING NODES]");
}
-(void) didStartParsingWays {
	[self checkForNodesFlush];
	DDLogInfo(@"[NOW PARSING WAYS]");
}
-(void) didStartParsingRelations {
	[self checkForWaysFlush];
	DDLogInfo(@"[NOW PARSING RELATIONS]");
}

- (void)parsingWillStart {
    DDLogInfo(@"[PARSING WILL START]");
}

- (void)parsingDidEnd {
    DDLogInfo(@"[PARSING DID END");
}

-(void) onNodeFound:(Node *)node {
	if (!ignoreNodes) {
		//[roadNetwork addNodes:[NSArray arrayWithObject:node]];
		[nodesBuffer addObject:node];
		//if (node.tags) 
		//	NSLog(@"this node has tags : %@", node.tags);
		nodesCounter++;
		if (nodesCounter%bufferMaxSize==0) {
			[self checkForNodesFlush];
		}
	}
}

-(void) onWayFound:(Way *)way {
	[waysBuffer addObject:way];
	if ([way.nodesIds count]==0)
		DDLogWarn(@"WARNING No Node for WAY %lldi", way.elementID);
	//NSLog(@"Way %lld has nodes : %@", way.elementID, way.nodesIds);
	waysCounter++;
	if (waysCounter%(bufferMaxSize/20)==0) {
		[self checkForWaysFlush];
	}
}

-(void) onRelationFound:(Relation *)relation {
	//NSLog(@"relation found");
	[self.outputDao addRelation:relation];
}

-(BOOL) checkForNodesFlush {
	if ([nodesBuffer count]!=0) {
		DDLogInfo(@"parsed %lu nodes", (unsigned long)nodesCounter);
		[self.outputDao addNodes:nodesBuffer];
		[nodesBuffer removeAllObjects];
		return YES;
	} else {
		return NO;
	}
}

-(BOOL) checkForWaysFlush {
	if ([waysBuffer count]!=0) {
		DDLogInfo(@"parsed %lu ways", (unsigned long)waysCounter);
		DDLogInfo(@"now populating corresponding nodes");
		for (int i=0; i<[waysBuffer count]; i++) {
			Way* w =[waysBuffer objectAtIndex:i];
			NSArray* n =[self.outputDao getNodesForWay:w];
			w.nodes=n;
		}
		DDLogInfo(@"Nodes populated, now flushing...");
		[self.outputDao addWays:waysBuffer];
		DDLogInfo(@"Flush !");
		[waysBuffer removeAllObjects];
		return YES;
	}else {
		return NO;
	}

}

@end
