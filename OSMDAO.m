//
//  RoadNetworkDAO.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSMDAO.h"
//#import <CoreLocation/CoreLocation.h>
#import "Node.h"
#import "Way.h"
#import "Relation.h"
//#import "GeoTools.h"
//#import "spatialite.h"


@interface OSMDAO (privateAPI)
-(void) initDB;
-(void) addNodeAsGeom:(Node*)node;
-(void) addNodesIDsForWay:(Way*)way;
-(void) updateWayInfoId:(NSInteger)wayInfoId toWaysWithIds:(NSArray*)idsArray;

/*-(NSUInteger) getRoadDefinitionMatchingArrayOfWays:(NSArray*)ways reference:(NSString*)ref;
-(NSUInteger) getRoadDefinitionMatchingArrayOfWays:(NSArray*)ways reference:(NSString*)ref andSection:(NSString*)section;

-(NSUInteger) getRoadDefinitionMatchingRoadReference:(NSString*)ref section:(NSString*)section andAngle:(NSUInteger)angleInDegrees;
-(NSDictionary*) splitRelationForBothDrivingDirectionsForRelation:(NSUInteger)relationId;

-(NSDictionary*) groupBySection:(NSArray*) arraysOfWays;
-(CLLocation*) firstNodeLocation:(NSArray*)arrayOfWays;
-(CLLocation*) lastNodeLocation:(NSArray*)arrayOfWays;
-(CLLocation*) middleLocation:(NSArray *)arrayOfWays;
-(BOOL) isSameSection:(NSArray*)waysA as:(NSArray*)waysB;

+(NSString*) waysIdsFromAsString:(NSArray*)arrayOfWays;
-(void) tagOffsetFor:(NSArray*) arrayOfWays;*/

@end

@implementation OSMDAO

@synthesize dbHandle, filePath;
@synthesize databaseQueue;
@synthesize delegate;
//@synthesize database;

+(void) initialize {
	//spatialite_init (1);
	//[self createGeometryForWayId:1];
}

-(id) initWithFilePath:(NSString*)resPath overrideIfExists:(BOOL)override {
	if (self!=[super init])
		return nil;
	filePath = resPath;
	//NSString *resPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"rNetwork.db"];
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:resPath];
	if (exists && override) {
		//[[NSFileManager defaultManager] removeItemAtPath:resPath error:nil];
	}
	int ret = sqlite3_open_v2 ([resPath cStringUsingEncoding:NSUTF8StringEncoding], &dbHandle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
	if (ret != SQLITE_OK)
		NSLog(@"error when opening %@", resPath);
	/*else
		NSLog(@"OPEN OK");*/
	if (!exists || (exists && override)) {
		[self initDB];
	}
    close(dbHandle);
    //database = [[FMDatabase alloc] initWithPath:filePath];
    //[database open];
    databaseQueue = [FMDatabaseQueue databaseQueueWithPath:filePath];
	return self;
	
}

-(id) initWithFilePath:(NSString*)resPath {
	return [self initWithFilePath:resPath overrideIfExists:NO];
}

-(void) dealloc {
	if (dbHandle)
		sqlite3_close(dbHandle);
}

-(void) initDB {
	NSString* p = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"roadNetworkInit.sql"];
	//NSLog(@"Path %@", p);
	NSString* initScript = [NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:nil];
	//NSLog(@"init script %@", initScript);
	char* errMsg = NULL;
	const char *sql = [initScript cStringUsingEncoding:NSUTF8StringEncoding];
	int returnValue = sqlite3_exec(dbHandle, sql, NULL, NULL, &errMsg);
	if (returnValue!=SQLITE_OK)
		NSAssert1(0, @"Error initializing DB. '%s'", sqlite3_errmsg(dbHandle));
    
    
}

/*
-(void) initDBForSpeedCamera {
	NSString* p = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"radarsInit.sql"];
	NSString* initScript = [NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:nil];
	char* errMsg = NULL;
	const char *sql = [initScript cStringUsingEncoding:NSUTF8StringEncoding];
	int returnValue = sqlite3_exec(dbHandle, sql, NULL, NULL, &errMsg);
	if (returnValue!=SQLITE_OK)
		NSAssert1(0, @"Error initializing DB for radars. '%s'", sqlite3_errmsg(dbHandle));
}*/
/*
-(GEOSGeometry*) createGeometryForWayId:(NSUInteger*)wayId {
	NSLog(@"GEOS version %s", GEOSversion());
	GEOSMessageHandler notice;
	GEOSMessageHandler error;
	GEOSContextHandle_t* GEOSHandle = initGEOS_r(notice, error);
	GEOSWKBReader * reader = GEOSWKBReader_create();
	//GEOSWKBReader_read(GEOSWKBReader* reader, const unsigned char *wkb, size_t size);
}*/



-(void) optimizeDB {
	NSString* p = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"optimizeDb.sql"];
	NSString* initScript = [NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:nil];
	char* errMsg = NULL;
	const char *sql = [initScript cStringUsingEncoding:NSUTF8StringEncoding];
	int returnValue = sqlite3_exec(dbHandle, sql, NULL, NULL, &errMsg);
	if (returnValue!=SQLITE_OK)
		NSAssert1(0, @"Error optimizing db. '%s'", sqlite3_errmsg(dbHandle));
	else 
		NSLog(@"[OPTIMIZE] OK" );
}

-(void) addContentFrom:(OSMDAO*)networkB {
	//NSString* req = @;
	NSLog(@"merging with %@", networkB.filePath); 
	//char* errMsg = NULL;
	sqlite3_stmt *statement;
	sqlite3_stmt *insertStmt;
	//char* sql = [req cStringUsingEncoding:NSUTF8StringEncoding];
	int returnValue = sqlite3_prepare_v2(networkB.dbHandle, "SELECT * from ways", -1, &statement, NULL);
	returnValue = sqlite3_prepare_v2(dbHandle, "INSERT into ways values(?,?)", -1, &insertStmt, NULL);
	
	//returnValue = sqlite3_exec(dbHandle, "BEGIN", NULL, NULL, &errMsg);
	while (sqlite3_step(statement) == SQLITE_ROW) {
		NSUInteger wayID = sqlite3_column_int(statement,0);
		const void* geom = sqlite3_column_blob(statement, 1);
		NSUInteger geomSize = sqlite3_column_bytes(statement, 1);
		sqlite3_reset(insertStmt);
		sqlite3_bind_int(insertStmt, 1, wayID);
		sqlite3_bind_blob(insertStmt, 2, geom, geomSize, SQLITE_STATIC);
		sqlite3_step(insertStmt);
	}
	//returnValue = sqlite3_exec(dbHandle, "COMMIT", NULL, NULL, &errMsg);
	
	sqlite3_finalize(insertStmt);
	sqlite3_finalize(statement);
}

-(NSArray*) getMotorwaysRelationsIds {
	NSMutableArray* relations = [NSMutableArray array];
	sqlite3_stmt *statement;
	sqlite3_prepare_v2(dbHandle, "select relationid from relations_tags where value like \"A %\"", -1, &statement, NULL);
	while (sqlite3_step(statement) == SQLITE_ROW) {
		NSUInteger relationID = sqlite3_column_int(statement,0);
		[relations addObject:[NSNumber numberWithInt:relationID]];
	}
	sqlite3_finalize(statement);
	
	return relations;
}

-(NSString *)sqliteCurrentVersionString:(Element *)newElement
{
    return [NSString stringWithFormat:@"select version from %@ where id = %lld",[OSMDAO tableName:newElement],newElement.elementID];
}

#pragma mark -
#pragma mark Nodes operations

-(void) addNodes:(NSArray*)nodes {
    
    __block NSMutableArray * newNodes = [NSMutableArray array];
    __block NSMutableArray * updateNodes = [NSMutableArray array];
    [databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL success = NO;
        success = [db beginTransaction];
        for (int i=0; i<[nodes count];i++) {
            Node * node = nodes[i];
            BOOL shouldUpdate = YES;
            BOOL alreadyExists = NO;
            FMResultSet * set = [db executeQuery:[self sqliteCurrentVersionString:node]];
            if ([set next]) {
                int64_t currentVersion = [set longForColumn:@"version"];
                alreadyExists = (currentVersion > 0);
                shouldUpdate = (currentVersion < node.version);
            }
            [set close];
            
            if (shouldUpdate) {
                success = [db executeUpdate:[OSMDAO sqliteInsertOrReplaceNodeString:node]];
                if (success) {
                    [db executeUpdate:@"DELETE FROM nodes_tags WHERE node_id = ?",[NSNumber numberWithLongLong:node.elementID]];
                    for(NSString * osmKey in node.tags)
                    {
                        BOOL tagInsertOK = [db executeUpdate:@"insert or replace into nodes_tags(node_id,key,value) values(?,?,?)",[NSNumber numberWithLongLong:node.elementID],osmKey,node.tags[osmKey]];
                    }
                }
                if (alreadyExists) {
                    [updateNodes addObject:node];
                }
                else
                {
                    [newNodes addObject:node];
                }
            }
            
        }
        
        success = [db commit];
    }];
    
    if ([self.delegate respondsToSelector:@selector(didFinishSavingElements:)]) {
        [self.delegate didFinishSavingElements:nodes];
    }
    if ([self.delegate respondsToSelector:@selector(didFinishSavingNewElements:updatedElements:)]) {
        [self.delegate didFinishSavingNewElements:newNodes updatedElements:updateNodes];
    }
}

+(NSString *)sqliteInsertOrReplaceNodeString:(Node*)node
{
    return [NSString stringWithFormat:@"insert or replace into nodes(id,latitude,longitude,user,uid,changeset,version,timestamp) values (%lld,%f,%f,\'%@\',%lld,%lld,%lld,\'%@\')",node.elementID,node.latitude,node.longitude,node.user,node.uid,node.changeset,node.version,[node formattedDate]];
}
+(NSArray *)sqliteInsertNodeTagsString:(Node *)node
{
    NSMutableArray * sqlStringArray = [NSMutableArray array];
    if ([node.tags count]) {
        for (NSString * key in node.tags)
        {
            NSString *sqlString = [NSString stringWithFormat:@"insert or replace into nodes_tags(node_id,key,value) values(%lld,\'%@\',\'%@\')",node.elementID,key,node.tags[key]];
            [sqlStringArray addObject:sqlString];
        }
    }
    return sqlStringArray;
    
}

/*
-(void) addNodeAsGeom:(Node*)node {
	NSString* req = [NSString stringWithFormat:@"INSERT INTO nodesAsGeom (nodeid, geom) VALUES (%i, GeomFromText('POINT(%f %f)', 4326))", 
					 node.elementID, node.longitude, node.latitude];
	//NSLog(@"req for way is %@", req);
	char* errMsg = NULL;
	char* sql = [req cStringUsingEncoding:NSUTF8StringEncoding];
	NSInteger returnValue = sqlite3_exec(dbHandle, sql, NULL, NULL, &errMsg);
	if (returnValue!=SQLITE_OK)
		NSAssert1(0, @"Error initializing DB. '%s'", sqlite3_errmsg(dbHandle));
	
}
 */

-(Node*) getNodeFromID:(int64_t)nodeId withTags:(BOOL)withTags{
    
    __block Node * node = nil;
    [databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * result = [db executeQueryWithFormat:@"SELECT * FROM nodes where id=%lld limit 1",nodeId];
        if ([result next]) {
            node = [[Node alloc] init];
            node.elementID = [result longLongIntForColumn:@"id"];
            node.user = [result stringForColumn:@"user"];
            node.uid = [result longLongIntForColumn:@"uid"];
            node.version = [result longLongIntForColumn:@"version"];
            node.changeset = [result stringForColumn:@"changeset"];
            [node addDateWithString:[result stringForColumn:@"timestamp"]];
            node.latitude = [result doubleForColumn:@"latitude"];
            node.longitude = [result doubleForColumn:@"longitude"];
            node.action = [result stringForColumn:@"action"];
            
            if (withTags) {
                node.tags = [[self getTagsForElement:node] mutableCopy];
            }
        }
        [result close];
    }];
    
    return node;
    
}

+(NSString *)tableName:(Element *)element
{
    NSString * tableName = @"";
    if ([element isKindOfClass:[Node class]]) {
        tableName = @"nodes";
    }
    else if ([element isKindOfClass:[Way class]])
    {
        tableName = @"ways";
    }
    else if ([element isKindOfClass:[Relation class]])
    {
        tableName = @"relations";
    }
    return tableName;
    
}

-(NSDictionary *)getTagsForElement:(Element *)element
{
    __block NSMutableDictionary * tags = [NSMutableDictionary dictionary];
    
    [databaseQueue inDatabase:^(FMDatabase *db) {
        NSString * tableName = @"";
        NSString * idColumnName = @"";
        if ([element isKindOfClass:[Node class]]) {
            tableName = @"nodes_tags";
            idColumnName = @"node_id";
        }
        else if ([element isKindOfClass:[Way class]])
        {
            tableName = @"ways_tags";
            idColumnName = @"way_id";
        }
        else if ([element isKindOfClass:[Relation class]])
        {
            tableName = @"relations_tags";
            idColumnName = @"relation_id";
        }
        
        FMResultSet * results = [db executeQueryWithFormat:@"select key, value from %@ where %@=%lld",tableName,idColumnName,element.elementID];
        while ([results next]) {
            [tags setObject:[results stringForColumn:@"value"] forKey:[results stringForColumn:@"key"]];
        }
    }];
    
    
    return tags;
    
}

-(NSArray*) getNodesForWay:(Way*)way {
	NSMutableArray* nodes = [NSMutableArray arrayWithCapacity:[way.nodes count]];
	for (int i=0; i<[way.nodesIds count]; i++)  {
		int64_t nodeId = [[way.nodesIds objectAtIndex:i] longLongValue];
		Node* n = [self getNodeFromID:nodeId withTags:NO];
		if (n!=nil)
			[nodes addObject:n];
		else
			NSLog(@"Cannot find node %lld for WAY ID %lli tags:%@", nodeId, way.elementID, way.tags);

	}
	return nodes;
}

#pragma mark -
#pragma mark Ways Operations

-(void) deleteWaysWithIds:(NSArray*)waysIds {
	NSString* waysIdsSql = @"";
	for (int i=0; i<[waysIds count]; i++) {
		waysIdsSql = [waysIdsSql stringByAppendingFormat:@"%@%@", [waysIds objectAtIndex:i], (i<[waysIds count]-1)?@",":@""];
	}
	char* errMsg = NULL;
	const char *sql = [[NSString stringWithFormat:@"DELETE from ways where wayid IN (%@)", waysIdsSql] cStringUsingEncoding:NSUTF8StringEncoding];
	int returnValue = sqlite3_exec(dbHandle, sql, NULL, NULL, &errMsg);
	if (returnValue!=SQLITE_OK)
		NSAssert1(0, @"Error initializing DB. '%s'", sqlite3_errmsg(dbHandle));
}

-(Way*) getWayWithID:(int64_t)wayid {
	//NSLog(@"geting way %i", wayid );
	Way* way = [[Way alloc] init];
	way.elementID=wayid;
	sqlite3_stmt *stmt;
	const char *sql = "SELECT nodeid from ways_nodes where wayid=? ORDER BY rowid";
	if(sqlite3_prepare_v2(dbHandle, sql, -1, &stmt, NULL) != SQLITE_OK)
		NSAssert1(0, @"Error while creating statement. '%s'", sqlite3_errmsg(dbHandle));
	sqlite3_bind_int(stmt, 1, wayid);
	while (sqlite3_step(stmt)==SQLITE_ROW) {
		NSInteger nodeid = sqlite3_column_int(stmt, 0);
		//Way* way = [self getWayWithID:memberId];
		[way.nodesIds addObject:[NSNumber numberWithInt:nodeid]];
		//sqlite3_reset(stmt);
	}
	sqlite3_finalize(stmt);

	//Populate length
	const char *getLengthSql = "SELECT length from ways where wayid=?";
	if(sqlite3_prepare_v2(dbHandle, getLengthSql, -1, &stmt, NULL) != SQLITE_OK)
		NSAssert1(0, @"Error while creating statement. '%s'", sqlite3_errmsg(dbHandle));
	sqlite3_bind_int(stmt, 1, wayid);
	sqlite3_step(stmt);
	NSUInteger length = sqlite3_column_int(stmt, 0);
	way.length=length;
	
	sqlite3_finalize(stmt);
	return way;
}

-(void) addWays:(NSArray*)ways {
    
    __block NSMutableArray * newWays = [NSMutableArray array];
    __block NSMutableArray * updateWays = [NSMutableArray array];
    [databaseQueue inDatabase:^(FMDatabase *db) {
        db.logsErrors = YES;
        BOOL success = NO;
        success = [db beginTransaction];
        for (int i=0; i<[ways count];i++) {
            Way * way = ways[i];
            BOOL shouldUpdate = YES;
            BOOL alreadyExists = NO;
            FMResultSet * set = [db executeQuery:[self sqliteCurrentVersionString:way]];
            if ([set next]) {
                int64_t currentVersion = [set longForColumn:@"version"];
                alreadyExists = (currentVersion > 0);
                shouldUpdate = (currentVersion < way.version);
            }
            [set close];
            
            if (shouldUpdate) {
                success = [db executeUpdate:[OSMDAO sqliteInsertOrReplaceWayString:way]];
                if (success) {
                    [db executeUpdate:@"DELETE FROM ways_nodes WHERE way_id = ?",[NSNumber numberWithLongLong:way.elementID]];
                    [db executeUpdate:@"DELETE FROM ways_tags WHERE way_id = ?",[NSNumber numberWithLongLong:way.elementID]];
                    NSArray * sql = [OSMDAO sqliteInsertOrReplaceWayNodesString:way];
                    
                    for (NSString * sqlString in sql)
                    {
                        if ([sqlString length]) {
                            success = [db executeUpdate:sqlString];
                        }
                        else
                        {
                            NSLog(@"ERROR NO Way Nodes");
                        }
                    }
                    
                    
                    
                    for(NSString * osmKey in way.tags)
                    {
                        BOOL tagInsertOK = [db executeUpdate:@"insert or replace into ways_tags(way_id,key,value) values(?,?,?)",[NSNumber numberWithLongLong:way.elementID],osmKey,way.tags[osmKey]];
                    }
                    
                    if (alreadyExists) {
                        [updateWays addObject:way];
                    }
                    else
                    {
                        [newWays addObject: way];
                    }
                }
            }
        }
        
        success = [db commit];
    }];
	if ([self.delegate respondsToSelector:@selector(didFinishSavingElements:)]) {
        [self.delegate didFinishSavingElements:ways];
    }
    if ([self.delegate respondsToSelector:@selector(didFinishSavingNewElements:updatedElements:)]) {
        [self.delegate didFinishSavingNewElements:newWays updatedElements:updateWays];
    }
}

/*
 LINESTRING(756881.706704 4850692.62625,
 760361.595005 4852743.267975,
 759582.880944 4855493.610807,
 757549.382306 4855414.551183,
 755734.189332 4856112.118807,
 755020.910885 4855996.887913,
 754824.031873 4854723.577451,
 756021.000385 4850937.420842,
 756881.706704 4850692.62625)
 */
+(NSString *)sqliteInsertOrReplaceWayString:(Way*)way
{
    return [NSString stringWithFormat:@"insert or replace into ways(id,user,uid,changeset,version,timestamp) values (%lld,\'%@\',%lld,%lld,%lld,\'%@\')",way.elementID,way.user,way.uid,way.changeset,way.version,[way formattedDate]];
}

+(NSArray *) sqliteInsertOrReplaceWayNodesString:(Way*)way {
    NSMutableArray * sqlStringArray =[NSMutableArray array];
    if ([way.nodes count]) {
        for (int i=0; i<[way.nodesIds count]; i++) {
            int64_t nodeid= [(NSNumber*)[way.nodesIds objectAtIndex:i] longLongValue];
            NSString * sqlString = [NSMutableString stringWithFormat:@"insert or replace into ways_nodes(way_id,node_id,local_order) values(%lld,%lld,%d)",way.elementID,nodeid,i];
            [sqlStringArray addObject:sqlString];
            
        }
    }
    return sqlStringArray;
}

#pragma mark -
#pragma mark Relation Operations

-(void) addRelation:(Relation*) rel {
	
	__block BOOL alreadyExists = NO;
    [databaseQueue inDatabase:^(FMDatabase *db) {
        db.logsErrors = YES;
        [db beginTransaction];
        
        BOOL shouldUpdate = YES;
        
        FMResultSet * set = [db executeQuery:[self sqliteCurrentVersionString:rel]];
        if ([set next]) {
            int64_t currentVersion = [set longForColumn:@"version"];
            alreadyExists = (currentVersion > 0);
            shouldUpdate = (currentVersion < rel.version);
        }
        [set close];
        if (shouldUpdate) {
            BOOL insertOK = [db executeUpdate:[OSMDAO sqliteInsertOrReplaceRelationString:rel]];
            
            if (insertOK) {
                [db executeUpdate:@"DELETE FROM relations_members WHERE relation_id = ?",[NSNumber numberWithLongLong:rel.elementID]];
                [db executeUpdate:@"DELETE FROM relations_tags WHERE relation_id = ?",[NSNumber numberWithLongLong:rel.elementID]];
                
                for (int i=0; i<[rel.members count]; i++) {     
                    Member* m = (Member*)[rel.members objectAtIndex:i];
                    [db executeUpdate:@"insert or replace into relations_members(relation_id,type,ref,role,local_order) values (?,?,?,?,?)",[NSNumber numberWithLongLong:rel.elementID],m.type,[NSNumber numberWithLongLong:m.ref],m.role,[NSNumber numberWithInt:i]];
                    
                }
                if ([rel.tags count]) {
                    
                    for(NSString * osmKey in rel.tags)
                    {
                        BOOL tagInsertOK = [db executeUpdate:@"insert or replace into relations_tags(relation_id,key,value) values(?,?,?)",[NSNumber numberWithLongLong:rel.elementID],osmKey,rel.tags[osmKey]];
                    }
                }
            }
        }
        [db commit];
    }];
    
    if ([self.delegate respondsToSelector:@selector(didFinishSavingElements:)]) {
        [self.delegate didFinishSavingElements:@[rel]];
    }
    
    if ([self.delegate respondsToSelector:@selector(didFinishSavingNewElements:updatedElements:)]) {
        if (alreadyExists) {
            [self.delegate didFinishSavingNewElements:nil updatedElements:@[rel]];
        }
        else{
            [self.delegate didFinishSavingNewElements:@[rel] updatedElements:nil];
        }
        
    }
	
    
}

+(NSString *) sqliteInsertOrReplaceRelationString:(Relation *)relation
{
    return [NSString stringWithFormat:@"insert or replace into relations(id,user,uid,changeset,version,timestamp) values (%lld,\'%@\',%lld,%lld,%lld,\'%@\')",relation.elementID,relation.user,relation.uid,relation.changeset,relation.version,[relation formattedDate]];
}

-(NSArray*) getWaysIdsMembersForRelationWithId:(int64_t) relationId {
    //NSDictionary* tags = [self tagsForRelation:relationId];
    sqlite3_stmt *stmt;
    NSMutableArray* membersIds = [NSMutableArray array]; 
    const char *sql = sql = "select ref from relations_members where type='way' AND relationid=?";
	if(sqlite3_prepare_v2(dbHandle, sql, -1, &stmt, NULL) != SQLITE_OK)
		NSAssert1(0, @"Error while creating statement. '%s'", sqlite3_errmsg(dbHandle));
    sqlite3_bind_int(stmt, 1, (int)relationId);
    while (sqlite3_step(stmt)==SQLITE_ROW) {
        int memberId = sqlite3_column_int(stmt, 0);
		[membersIds addObject:[NSNumber numberWithInt:(int)memberId]];
    }
    return membersIds;
}

-(Relation*) getRelationWithID:(int64_t) relationid {
	Relation* relation = [[Relation alloc] init];
	relation.elementID=relationid;
	sqlite3_stmt *stmt;
	const char *sql = "SELECT ref from relations_members where relationid=? ORDER BY rowid";
	if(sqlite3_prepare_v2(dbHandle, sql, -1, &stmt, NULL) != SQLITE_OK)
		NSAssert1(0, @"Error while creating statement. '%s'", sqlite3_errmsg(dbHandle));
	sqlite3_bind_int(stmt, 1, relationid);
	while (sqlite3_step(stmt)==SQLITE_ROW) {
		NSInteger memberId = sqlite3_column_int(stmt, 0);
		Way* way = [self getWayWithID:memberId];
		if (way==nil)
			NSAssert1(0, @"Cannot fin way %i", memberId);
		[relation.members addObject:way];
		//sqlite3_reset(stmt);
	}
	sqlite3_finalize(stmt);
	//tags should be added as well
	return relation;
		
}


/*
#pragma mark -
-(NSUInteger) getRoadDefinitionMatchingRoadReference:(NSString*)ref andAngle:(NSUInteger)angleInDegrees {
	return [self getRoadDefinitionMatchingRoadReference:ref section:nil andAngle:angleInDegrees];
}

-(NSUInteger) getRoadDefinitionMatchingRoadReference:(NSString*)ref section:(NSString*)section andAngle:(NSUInteger)angleInDegrees {
	NSString* dir = [GeoTools stringFromCourse:angleInDegrees];
	sqlite3_stmt *stmt;
	NSString* sqlAsString = [NSString stringWithFormat:@"SELECT rowid from roadsDefinitions where ref=\"%@\" AND course=%i %@",
					 ref, angleInDegrees, (section==nil)?@"":[NSString stringWithFormat:@" AND section=\"%@\"", section]];
	const char *sql = [sqlAsString cStringUsingEncoding:NSUTF8StringEncoding];
	if(sqlite3_prepare_v2(dbHandle, sql, -1, &stmt, NULL) != SQLITE_OK)
		NSAssert1(0, @"Error while creating statement. '%s'", sqlite3_errmsg(dbHandle));
	//sqlite3_bind_text(stmt, 1, [ref UTF8String], -1, SQLITE_TRANSIENT);
	//sqlite3_bind_text(stmt, 2, [dir UTF8String], -1, SQLITE_TRANSIENT);
	NSInteger rowid=0;
	if (sqlite3_step(stmt)==SQLITE_ROW) {
		rowid= sqlite3_column_int(stmt, 0);
	}
	sqlite3_finalize(stmt);
	if (rowid!=0)
		return rowid;
	else {
		if (section==nil)
			sqlAsString = [NSString stringWithFormat:@"INSERT into roadsDefinitions values(\"%@\",NULL, \"%@\",NULL)", ref, dir];
		else {
			sqlAsString = [NSString stringWithFormat:@"INSERT into roadsDefinitions values(\"%@\",NULL, \"%@\",\"%@\")", ref, dir, section];
		}
		const char *insert = [sqlAsString cStringUsingEncoding:NSUTF8StringEncoding];
		if(sqlite3_prepare_v2(dbHandle, insert, -1, &stmt, NULL) != SQLITE_OK)
			NSAssert1(0, @"Error while creating statement. '%s'", sqlite3_errmsg(dbHandle));
		sqlite3_step(stmt);
		
		rowid = sqlite3_last_insert_rowid(dbHandle);
		NSLog(@"[CREATING DEF] %i: %@%@ - %@", rowid, ref, (section==nil)?@"":[NSString stringWithFormat:@"(section %@)", section],dir); 
		sqlite3_finalize(stmt);
		return rowid;
	}
}*/


/*
-(void) associateNetworkToRoadsDefinitions {
	sqlite3_stmt *stmt;
	
	const char * sqlA="ALTER TABLE ways ADD COLUMN info INTEGER";
	int returnValue = sqlite3_exec(dbHandle, sqlA, NULL, NULL, NULL);
	if (returnValue!=SQLITE_OK)
		NSAssert1(0, @"Error adding column. '%s'", sqlite3_errmsg(dbHandle));
	
	const char *sql = "select relationid, value from relations_tags where key=\"ref\"";
	if(sqlite3_prepare_v2(dbHandle, sql, -1, &stmt, NULL) != SQLITE_OK)
		NSAssert1(0, @"Error while creating statement. '%s'", sqlite3_errmsg(dbHandle));
	while (sqlite3_step(stmt)==SQLITE_ROW) {
		//only get the first result
		NSUInteger relId = sqlite3_column_int(stmt, 0);
		NSString* ref = [NSString stringWithUTF8String:(char*) sqlite3_column_text(stmt, 1)];
		NSLog(@"splitting relations for %@ (rel=%i) ...", ref, relId);
		NSDictionary* waysSplitted = [self splitRelationForBothDrivingDirectionsForRelation:relId];
		BOOL hasOnlyOneSection = ([waysSplitted count]==1);
		NSArray* allSectionsKeys=[waysSplitted allKeys]; 
		for (int i=0; i<[allSectionsKeys count]; i++) {
			NSObject* sectionIdentifier = [allSectionsKeys objectAtIndex:i];
			NSArray* currentSection = [waysSplitted objectForKey:sectionIdentifier];
			for (int j=0; j<2; j++) {
				NSArray* arrayOfWays = [currentSection objectAtIndex:j];
				NSUInteger roadDefinition = [self getRoadDefinitionMatchingArrayOfWays:(arrayOfWays) reference:ref andSection:(hasOnlyOneSection)?nil:(NSString*)sectionIdentifier];
				//NSLog(@"Corresponding Road Def %i", roadDefinition);
				if (roadDefinition==0)
					NSLog(@"[CANNOT MATCH TO ANY DEFINITION :(");
				else {
					//apply the road def to all the ways.
					const char * r=[[NSString stringWithFormat:@"UPDATE ways SET definitionid=%i where wayid IN (%@)", 
									 roadDefinition, [OSMDAO waysIdsFromAsString:arrayOfWays]] cStringUsingEncoding:NSUTF8StringEncoding];
					//NSLog(@"req is %s",r);
					int returnValue = sqlite3_exec(dbHandle, r, NULL, NULL, NULL);
					if (returnValue!=SQLITE_OK)
						NSAssert1(0, @"Error updating definition. '%s'", sqlite3_errmsg(dbHandle));
					
					[self tagOffsetFor:arrayOfWays];
				}
			}
		}
	}
	sqlite3_finalize(stmt);
}
 */

/*
+(NSString*) waysIdsFromAsString:(NSArray*)arrayOfWays {
	NSString* s=@"";
	for (int i=0; i<[arrayOfWays count]; i++) {
		s =[s stringByAppendingFormat:@"%i%@", ((Way*)[arrayOfWays objectAtIndex:i]).wayId, (i!=[arrayOfWays count]-1)?@", ":@""];
	}
	return s;
}

-(void) tagOffsetFor:(NSArray*) arrayOfWays {
	int returnValue = sqlite3_exec(dbHandle, "BEGIN", NULL, NULL, NULL);
	if (returnValue!=SQLITE_OK)
		NSAssert1(0, @"Error initializing DB. '%s'", sqlite3_errmsg(dbHandle));
	
	NSUInteger offset=0;
	for (int i=0; i<[arrayOfWays count]; i++) {
		Way* w = [arrayOfWays objectAtIndex:i];
		const char * r=[[NSString stringWithFormat:@"UPDATE ways SET offset=%i where wayid=%i", 
						 offset, w.wayId] cStringUsingEncoding:NSUTF8StringEncoding];
		//NSLog(@"req is %s",r);
		int returnValue = sqlite3_exec(dbHandle, r, NULL, NULL, NULL);
		if (returnValue!=SQLITE_OK)
			NSAssert1(0, @"Error updating way offset. '%s'", sqlite3_errmsg(dbHandle));
		NSLog(@"offset before : %i", offset);
		offset+=w.length;
		NSLog(@"offset after : +%i = %i", w.length,offset);
		
	}
	returnValue = sqlite3_exec(dbHandle, "COMMIT", NULL, NULL, NULL);
	if (returnValue!=SQLITE_OK)
		NSAssert1(0, @"Error initializing DB. '%s'", sqlite3_errmsg(dbHandle));
}

-(NSUInteger) getRoadDefinitionMatchingArrayOfWays:(NSArray*)ways reference:(NSString*)ref andSection:(NSString*)section{
	NSArray* allNodesIDs = ((Way*)[ways objectAtIndex:0]).nodesIds;
	NSUInteger nodeIdStart = [[allNodesIDs objectAtIndex:0] intValue];
	//last node of the first array of ways
	allNodesIDs = ((Way*)[ways lastObject]).nodesIds;
	NSUInteger nodeIdEnd = [[allNodesIDs lastObject] intValue];
	Node* n1 = [self getNodeFromID:nodeIdStart];
	CLLocationCoordinate2D startCoord;
	startCoord.latitude = n1.latitude;
	startCoord.longitude = n1.longitude;
	//NSLog(@"start %f,%f", startCoord.latitude, startCoord.longitude);
	
	Node* n2 = [self getNodeFromID:nodeIdEnd];
	CLLocationCoordinate2D endCoord;
	endCoord.latitude = n2.latitude;
	endCoord.longitude = n2.longitude;
	//NSLog(@"end %f,%f", endCoord.latitude, endCoord.longitude);
	
	double angleInDegrees = [GeoTools orientationForCoord:startCoord andCoord:endCoord];
	angleInDegrees = [GeoTools toDegrees:angleInDegrees];
	//NSLog(@"%@ : %f", ref,  angleInDegrees);
	NSUInteger roadDefinition = [self getRoadDefinitionMatchingRoadReference:ref section:section andAngle:angleInDegrees];
	//NSLog(@"Corresponding Road Def %i", roadDefinition);
	return roadDefinition;
}

-(NSUInteger) getRoadDefinitionMatchingArrayOfWays:(NSArray*)ways reference:(NSString*)ref {
	return [self getRoadDefinitionMatchingArrayOfWays:ways reference:ref andSection:nil];
}

-(NSDictionary*) groupBySection:(NSArray*) arraysOfWays {
	NSMutableArray* givenWays = [NSMutableArray arrayWithArray:arraysOfWays];
	NSMutableDictionary* sortedSections = [NSMutableDictionary dictionary];
	NSUInteger referenceIdx=0;
	NSUInteger targetIdx=1;
	BOOL keepOnIterating=YES;
	NSUInteger sectionsCount= 0;
	while (keepOnIterating) {
		NSArray* waysA = [givenWays objectAtIndex:referenceIdx];
		NSArray* waysB = [givenWays objectAtIndex:targetIdx];
		if ([self isSameSection:waysA as:waysB]) {
			//NSLog(@"two from the same section identified");
			[givenWays removeObject:waysA];
			[givenWays removeObject:waysB];
			referenceIdx=0;
			targetIdx=1;
			sectionsCount++;
			NSLog(@"[GROUPING] %i ways with %i ways => SECTION %i", [waysA count], [waysB count], sectionsCount); 
			[sortedSections setObject:[NSArray arrayWithObjects:waysA, waysB, nil] forKey:[NSNumber numberWithInt:sectionsCount]];
			
		} else {
			targetIdx++;
			if (targetIdx==[givenWays count]) {
				referenceIdx++;
				targetIdx=referenceIdx+1;
			}
		}
		if (referenceIdx==([givenWays count]))
			keepOnIterating =NO;
	}
	
	
	if ([[sortedSections allKeys] count]==2) {
		NSArray* firstSection = [sortedSections objectForKey:[NSNumber numberWithInt:1]];
		NSArray* secondSection = [sortedSections objectForKey:[NSNumber numberWithInt:2]];
		
		CLLocation* loc1 = [self middleLocation:[firstSection objectAtIndex:0]];
		CLLocation* loc2 = [self middleLocation:[secondSection objectAtIndex:0]];
		double course = [GeoTools orientationForCoord:loc2.coordinate andCoord:loc1.coordinate];
		course = [GeoTools toDegrees:course];
		NSLog(@"Section 1 ID : %@", [GeoTools stringFromCourse:course]);
		[sortedSections setObject:firstSection forKey:[GeoTools stringFromCourse:course]];
		course = [GeoTools orientationForCoord:loc1.coordinate andCoord:loc2.coordinate];
		course = [GeoTools toDegrees:course];
		NSLog(@"Section 2 ID : %@", [GeoTools stringFromCourse:course]);
		[sortedSections setObject:secondSection forKey:[GeoTools stringFromCourse:course]];
		
		[sortedSections removeObjectForKey:[NSNumber numberWithInt:1]];
		[sortedSections removeObjectForKey:[NSNumber numberWithInt:2]];
		
	} else {
		NSLog(@"[UNSSUPPORTED] NUMBER OF SECTIONS: %i", [[sortedSections allKeys] count]);
	}
	
	
	return sortedSections;
}

-(BOOL) isSameSection:(NSArray*)waysA as:(NSArray*)waysB {
	double distanceTolerance = 500;
	CLLocation* waysAstart = [self firstNodeLocation:waysA];
	CLLocation* waysAend = [self lastNodeLocation:waysA];
	CLLocation* waysBstart = [self firstNodeLocation:waysB];
	CLLocation* waysBend = [self lastNodeLocation:waysB];
	
	return [waysAstart distanceFromLocation:waysBend]<distanceTolerance &&
	[waysAend distanceFromLocation:waysBstart] < distanceTolerance;
}

-(CLLocation*) firstNodeLocation:(NSArray*)arrayOfWays {
	NSArray* allNodesIDs = ((Way*)[arrayOfWays objectAtIndex:0]).nodesIds;
	NSUInteger nodeIdStart = [[allNodesIDs objectAtIndex:0] intValue];
	Node* n1 = [self getNodeFromID:nodeIdStart];
	CLLocationCoordinate2D startCoord;
	startCoord.latitude = n1.latitude;
	startCoord.longitude = n1.longitude;
	return [[[CLLocation alloc] initWithLatitude:startCoord.latitude longitude:startCoord.longitude] autorelease];
}

-(CLLocation*) lastNodeLocation:(NSArray*)arrayOfWays {
	NSArray* allNodesIDs = ((Way*)[arrayOfWays lastObject]).nodesIds;
	NSUInteger nodeIdEnd = [[allNodesIDs lastObject] intValue];
	Node* n1 = [self getNodeFromID:nodeIdEnd];
	CLLocationCoordinate2D endCoord;
	endCoord.latitude = n1.latitude;
	endCoord.longitude = n1.longitude;
	return [[[CLLocation alloc] initWithLatitude:endCoord.latitude longitude:endCoord.longitude] autorelease];
}

-(CLLocation*) middleLocation:(NSArray*)arrayOfWays {
	CLLocation* first = [self firstNodeLocation:arrayOfWays];
	CLLocation* last = [self lastNodeLocation:arrayOfWays];
	double avgLat = (first.coordinate.latitude+last.coordinate.latitude)/2.0;
	double avgLong = (first.coordinate.longitude+last.coordinate.longitude)/2.0;
	return [[[CLLocation alloc] initWithLatitude:avgLat longitude:avgLong] autorelease];
}

-(NSDictionary*) splitRelationForBothDrivingDirectionsForRelation:(NSUInteger)relationId {
	Relation* rel = [self getRelationWithID:relationId];
	//NSLog(@"relation has %i ways", [rel.members count]);
	NSMutableArray* splittedParts = [NSMutableArray arrayWithCapacity:1];
	//NSLog(@"Rel %@ %@", rel , rel.members);
	NSUInteger currentPartIndex=-1;
	Way* referenceWay =nil;
	//Way* wayB = nil;
	NSString* p = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"A55_excluded.plist"];
	NSMutableArray* excludedWaysIds = [NSMutableArray arrayWithContentsOfFile:p];
	p = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"A84_excluded.plist"];
	[excludedWaysIds addObjectsFromArray:[NSArray arrayWithContentsOfFile:p]];
	[self deleteWaysWithIds:excludedWaysIds];
	for (int i=0; i<([rel.members count]); i++) {
		Way* w=nil; 
		w = [rel.members objectAtIndex:i];
		if ([w.nodesIds count]==0 || [excludedWaysIds indexOfObject:[NSNumber numberWithInt:w.wayId]]!=NSNotFound) {
			NSLog(@"ignoring way %@ (%@)", w, ([w.nodesIds count]==0)?@"empty":@"excluded");
			w=nil;
			
		}
		NSInteger commonNode=-1;
		if (referenceWay!=nil && w!=nil) {
			commonNode=[w getCommonNodeIdWith:referenceWay];
			if (commonNode!=-1) {
				if ([referenceWay isLastNodeId:commonNode]) {
					[[splittedParts objectAtIndex:currentPartIndex] addObject:w];
				} else {
					[[splittedParts objectAtIndex:currentPartIndex] insertObject:w atIndex:0];
				}
			}
		}
		
		if (commonNode==-1 && w!=nil) {
			NSMutableArray* p = [NSMutableArray arrayWithObject:w];
			[splittedParts addObject:p];
			currentPartIndex++;
		}
		
		if (w!=nil) {
			[referenceWay release];
			referenceWay=[w retain];
			//NSLog(@"reference is now %@", referenceWay);
		}
	}
	
	if ([splittedParts count] >1) {
		NSUInteger referenceIndex=0;
		NSUInteger targetIndex=1;
		BOOL keepOnMerging =YES;
		BOOL atLeastOneMergeDoneDuringOneCycle = NO;
		while (keepOnMerging) {
			
			//NSLog(@"Comparing %i with %i", referenceIndex, targetIndex); 
			NSMutableArray* part1 = [splittedParts objectAtIndex:referenceIndex];
			NSMutableArray* part2 = [splittedParts objectAtIndex:targetIndex];
			
			Way* part1StartWay = [part1 objectAtIndex:0];
			Way* part1EndWay = [part1 objectAtIndex:[part1 count]-1];
			Way* part2StartWay = [part2 objectAtIndex:0];
			Way* part2EndWay = [part2 objectAtIndex:[part2 count]-1];
			BOOL mergeDone=NO;
			if ([part1EndWay lastNodeId]==[part2StartWay firstNodeId]) {
				[part1 addObjectsFromArray:part2];
				//NSLog(@"merging %i with %i", referenceIndex, targetIndex);
				atLeastOneMergeDoneDuringOneCycle=YES;
				mergeDone=YES;
			}
			else 
				if ([part1StartWay firstNodeId]==[part2EndWay lastNodeId]) {
					//NSLog(@"merging %i with %i (revert)", referenceIndex, targetIndex);
					for (int i=0; i<[part2 count]; i++) {
						[part1 insertObject:[part2 objectAtIndex:i] atIndex:i];
					}
					atLeastOneMergeDoneDuringOneCycle=YES;
					mergeDone=YES;
				}  else {
					//NSLog(@"cannot do anything");
				}
			
			if (mergeDone) {
				[splittedParts removeObjectAtIndex:targetIndex];
				if (targetIndex>=[splittedParts count]-1) {
					referenceIndex++;
					targetIndex=(referenceIndex+1);
				}
			}
			else {
				if (targetIndex==[splittedParts count]-1) {
					referenceIndex++;
					targetIndex=(referenceIndex+1);
				} else {
					targetIndex++;
				}
			}
			if (referenceIndex>=([splittedParts count]-1)) {
				//do we start a new cycle ?
				if (atLeastOneMergeDoneDuringOneCycle) {
					//NSLog(@"starting a whole new cycle");
					referenceIndex=0;
					targetIndex=1;
					atLeastOneMergeDoneDuringOneCycle=NO;
				} else {
					keepOnMerging=NO;
				}
			}
		}
	}
	
	NSDictionary* sections;
	if ([splittedParts count]==2) { 
		NSLog(@"[OK] AFTER MERGE relation %i splitted in **2** parts ", relationId);
		sections = [NSDictionary dictionaryWithObjectsAndKeys:splittedParts, [NSNumber numberWithInt:1], nil];
	}
	else {
		NSLog(@"[OK] AFTER MERGE relation %i splitted in %i parts", relationId, [splittedParts count]);
		NSLog(@"%@", splittedParts);
		sections = [self groupBySection:splittedParts];
		NSLog(@"[OK] NOW GROUPED in %i sections %@", [[sections allKeys] count], [sections allKeys]);
	}
	return sections;
	
}*/


@end
