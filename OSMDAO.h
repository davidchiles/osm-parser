//
//  RoadNetworkDAO.h
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
//Uses the sqlite embedded in spatialite and not the platform one.
#import "sqlite3.h"
#import "Node.h"
#import "Way.h"
#import "Relation.h"

#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FMDatabaseQueue.h"

@protocol OSMDAODelegate <NSObject>

-(void)didFinishSavingNewElements:(NSArray *)newElements updatedElements:(NSArray *)updatedElements;

@end

@interface OSMDAO : NSObject {
	sqlite3* dbHandle;
	NSString* filePath;
}
/** The internal handle to the sqlite db */ 
@property (readonly) sqlite3* dbHandle;
/** The path to the db on the filesystem. */ 
@property (readonly) NSString* filePath;

@property (nonatomic,strong)id<OSMDAODelegate> delegate;

@property (nonatomic,strong)FMDatabaseQueue * databaseQueue;
//@property (nonatomic,strong)FMDatabase *database;

/** Inits a new OSMDAO */
-(id) initWithFilePath:(NSString*)filePath;

-(id) initWithFilePath:(NSString*)filePath overrideIfExists:(BOOL)override;

/** Executes an SQL script that remove the useless temporary tables / rows 
 created during sto*/
-(void) optimizeDB;

/** Copies content from another OSMDAO to this one. */ 
//-(void) addContentFrom:(OSMDAO*)networkB;

/** Stores the given nodes in one single transaction. */
-(void) addNodes:(NSArray*)nodes;

/** Returns a node from its nodeid. */
-(Node*) getNodeFromID:(int64_t)nodeId withTags:(BOOL)withTags;

-(NSArray*) getNodesForWay:(Way*)way;

-(Way*) getWayWithID:(int64_t)wayid;

-(void) addWays:(NSArray*)ways;

-(void) deleteWaysWithIds:(NSArray*)waysIds;

//-(void) addWay:(Way*)way;

-(void) addRelation:(Relation *)rel;

-(NSArray*) getMotorwaysRelationsIds;

-(Relation*) getRelationWithID:(int64_t) relationid;

//-(void) associateNetworkToRoadsDefinitions;

-(NSDictionary*) getTagsForElement:(Element *)element;



//-(NSDictionary*) tagsForWay:(int64_t) wayId;

-(NSArray*) getWaysIdsMembersForRelationWithId:(int64_t) relationId;


+(NSArray *)sqliteInsertTagsString:(Element *)element;
+(NSString *)sqliteInsertOrReplaceString:(Element*)element;

+(NSString *)tableName:(Element *)element;

#pragma DB normalization
//-(void) populateWaysInfo;

//-(NSInteger) updateOrSaveWayInfoWithName:(NSString*)name andReference:(NSString*)ref;



/*
//Returns a rowid
-(NSUInteger) getRoadDefinitionMatchingRoadReference:(NSString*)ref andAngle:(NSUInteger)angle;
 */
@end
