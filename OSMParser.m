//
//  OSMParser.m
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSMParser.h"

@implementation OSMParser

@synthesize delegate;

- (id)initWithOSMFile:(NSString*)osmFilePath {
	if (self!=[super init]) {
		return nil;
	}
	isFirstNode=YES;
	isFirstWay=YES;
	isFirstRelation=YES;
	NSData* data = [NSData dataWithContentsOfFile:osmFilePath];
	parser=[[TBXML alloc] initWithXMLData:data];
	return self;
}

-(id)initwithOSMData:(NSData *)data
{
    if (self!=[super init]) {
		return nil;
	}
	isFirstNode=YES;
	isFirstWay=YES;
	isFirstRelation=YES;
	parser=[[TBXML alloc] initWithXMLData:data];
	return self;
    
}

-(void) parse {
    [delegate parsingStart];
    NSDate * start = [NSDate date];
    double totalNodeTime = 0;
    double totalWayTime = 0;
    double totalRelationTime = 0;
    int numNodes = 0;
    int numWays = 0;
	TBXMLElement * root = parser.rootXMLElement;
    if(root)
    {
        if ([(NSObject*)delegate respondsToSelector:@selector(didStartParsingNodes)])
            [delegate didStartParsingNodes];
        
        NSDate * nodeStart = [NSDate date];
        numNodes = [self findAllNodes];
        totalNodeTime -= [nodeStart timeIntervalSinceNow];
        
        if ([(NSObject*)delegate respondsToSelector:@selector(didStartParsingWays)])
            [delegate didStartParsingWays];
        
        NSDate * wayStart = [NSDate date];
        numWays = [self findAllWays];
        totalWayTime -= [wayStart timeIntervalSinceNow];
        
        if ([(NSObject*)delegate respondsToSelector:@selector(didStartParsingRelations)])
            [delegate didStartParsingRelations];

        
        NSDate * relationStart = [NSDate date];
        numWays = [self findAllRelations];
        totalRelationTime -= [relationStart timeIntervalSinceNow];
        
        [delegate parsingEnd];
        
        NSTimeInterval time = [start timeIntervalSinceNow];
        NSLog(@"Total Time: %f",-1*time);
        NSLog(@"Node Time: %f - %f",totalNodeTime,totalNodeTime/numNodes);
        NSLog(@"Way Time: %f - %f",totalWayTime,totalWayTime/numWays);
    }
}

-(NSInteger)findAllNodes
{
    NSInteger numberOfNodes = 0;
    TBXMLElement * nodeXML = [TBXML childElementNamed:@"node" parentElement:parser.rootXMLElement];
    while (nodeXML) {
        numberOfNodes +=1;
        //int64_t newVersion = [[TBXML valueOfAttributeNamed:@"version" forElement:nodeXML] longLongValue];
        int64_t osmID = [[TBXML valueOfAttributeNamed:@"id" forElement:nodeXML] longLongValue];
        double lat = [[TBXML valueOfAttributeNamed:@"lat" forElement:nodeXML] doubleValue];
        double lon = [[TBXML valueOfAttributeNamed:@"lon" forElement:nodeXML] doubleValue];
        
        Node* node = [[Node alloc] init];
        node.elementID = osmID;
		node.latitude = lat;
		node.longitude = lon;
        currentElement = node;
        
        currentElement = node;
        [self findTags:nodeXML];
        
        [delegate onNodeFound:node];
        
        nodeXML = [TBXML nextSiblingNamed:@"node" searchFromElement:nodeXML];
    }
    return numberOfNodes;
    
}
-(NSInteger)findAllWays
{
    NSInteger numberOfWays = 0;
    TBXMLElement * wayXML = [TBXML childElementNamed:@"way" parentElement:parser.rootXMLElement];
    while (wayXML) {
        numberOfWays +=1;
        //int64_t newVersion = [[TBXML valueOfAttributeNamed:@"version" forElement:wayXML] longLongValue];
        int64_t osmID = [[TBXML valueOfAttributeNamed:@"id" forElement:wayXML] longLongValue];
        
        Way * way = [[Way alloc] init];
        way.elementID = osmID;
        currentElement = way;
        [self findTags:wayXML];
        [self findNodes:wayXML withWay:way];
        
        
        [delegate onWayFound:way];
        
        //newWay.isNoNameStreetValue = [newWay noNameStreet];
        
        wayXML = [TBXML nextSiblingNamed:@"way" searchFromElement:wayXML];
    }
    return numberOfWays;
    
}
-(NSInteger)findAllRelations
{
    NSInteger numberOfRelations = 0;
    TBXMLElement * relationXML = [TBXML childElementNamed:@"relation" parentElement:parser.rootXMLElement];
    
    while (relationXML) {
        numberOfRelations +=1;
        //int64_t newVersion = [[TBXML valueOfAttributeNamed:@"version" forElement:relationXML] longLongValue];
        int64_t osmID = [[TBXML valueOfAttributeNamed:@"id" forElement:relationXML] longLongValue];
        Relation * relation = [[Relation alloc] init];
        relation.elementID = osmID;
        
        currentElement = relation;
        [self findTags:relationXML];
        [self findMemebers:relationXML withRelation:relation];
        
        [delegate onRelationFound:relation];
        
        relationXML = [TBXML nextSiblingNamed:@"relation" searchFromElement:relationXML];
        
    }
    return numberOfRelations;
    
}

-(void)findTags:(TBXMLElement *)xmlElement
{
    TBXMLElement* tag = [TBXML childElementNamed:@"tag" parentElement:xmlElement];
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    while (tag) //Takes in tags and adds them to newNode
    {
        NSString* key = [TBXML valueOfAttributeNamed:@"k" forElement:tag];
        NSString* value = [[TBXML valueOfAttributeNamed:@"v" forElement:tag] stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        
        [dictionary setObject:value forKey:key];
        tag = [TBXML nextSiblingNamed:@"tag" searchFromElement:tag];
    }
    
    if (currentElement) {
        currentElement.tags= dictionary;
    }

}

-(void)findNodes:(TBXMLElement *)xmlElement withWay:(Way *)way
{
    
    //int64_t osmID = [[TBXML valueOfAttributeNamed:@"id" forElement:xmlElement] longLongValue];
    
    TBXMLElement* nd = [TBXML childElementNamed:@"nd" parentElement:xmlElement];
    
    while (nd) {
        int64_t nodeId = [[TBXML valueOfAttributeNamed:@"ref" forElement:nd] longLongValue];
		NSNumber* refAsNumber = [NSNumber numberWithLongLong:nodeId];
		[way.nodesIds addObject:refAsNumber];
    }
}
-(void)findMemebers:(TBXMLElement *)xmlElement withRelation:(Relation *)relation
{
    TBXMLElement * memberXML = [TBXML childElementNamed:@"member" parentElement:xmlElement];
    
    while (memberXML) {
        NSString * typeString = [TBXML valueOfAttributeNamed:@"type" forElement:memberXML];
        int64_t elementOsmID = [[TBXML valueOfAttributeNamed:@"ref" forElement:memberXML] longLongValue];
        NSString * roleString = [TBXML valueOfAttributeNamed:@"role" forElement:memberXML];
        
        
		Member* member = [[Member alloc] init];
		member.type=typeString;
		member.ref=elementOsmID;
		member.role=roleString;
		[relation.members addObject:member];
        
        memberXML= [TBXML nextSiblingNamed:@"member" searchFromElement:memberXML];
    }
    
}

//<node id="274026" lat="43.6113906" lon="7.1074235" user="Djam" uid="24982" visible="true" version="2" changeset="3759495" timestamp="2010-01-31T14:18:39Z"/>
//<way id="68063774" user="Bert Bos" uid="155462" visible="true" version="1" changeset="5234652" timestamp="2010-07-16T14:23:00Z">
//<nd ref="820399673"/>
//<nd ref="820688904"/>

/*
+(NSUInteger) asInteger:(NSString*)v {
	//NSUInteger idx = [v rangeOfString:@"."].location;
	//NSUInteger numberOfDecimals = [v length] - idx;
	v = [v stringByReplacingOccurrencesOfString:@"." withString:@""];
	NSUInteger value = [v intValue];
	return value;
}

- (void)parser:(AQXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqual:@"node"]) {
		NSString* latitudeAsString=(NSString*)[attributeDict objectForKey:@"lat"];
		NSString* longitudeAsString=(NSString*)[attributeDict objectForKey:@"lon"];
		NSUInteger nodeid = [(NSString*)[attributeDict objectForKey:@"id"] intValue]; 
		//NSLog(@"parsed %d(%i, %i)", nodeid, , [OSMParser asInteger:longitudeAsString]);
		Node* node = [[Node alloc] init];
		node.nodeId = nodeid;
		node.latitude = [latitudeAsString doubleValue];
		node.longitude = [longitudeAsString doubleValue];
		currentNode = node;
	} else if ([elementName isEqual:@"way"]) {
		NSUInteger wayid = [(NSString*)[attributeDict objectForKey:@"id"] intValue]; 
		currentWay=[[Way alloc] init];
		currentWay.wayId=wayid;
	} else if ([elementName isEqual:@"relation"]) {
		
		 <relation id="539184" user="Nikita006" uid="35470" visible="true" version="15" changeset="4285518" timestamp="2010-03-31T13:57:26Z">
		 <member type="way" ref="4726817" role=""/>
		 ....
		 <tag k="ref" v="D 535"/>
		 <tag k="route" v="road"/>
		 <tag k="type" v="route"/>
		 
		NSUInteger relationid = [(NSString*)[attributeDict objectForKey:@"id"] intValue]; 
		currentRelation=[[Relation alloc] init];
		currentRelation.relationId=relationid;
	} else if ([elementName isEqual:@"member"]) {
		NSString* type = (NSString*)[attributeDict objectForKey:@"type"]; 
		NSUInteger ref = [(NSString*)[attributeDict objectForKey:@"ref"] intValue]; 
		NSString* role = (NSString*)[attributeDict objectForKey:@"role"]; 
		Member* member = [[Member alloc] init];
		member.type=type;
		member.ref=ref;
		member.role=role;
		[currentRelation.members addObject:member];
		[member release];
		
	} else if ([elementName isEqual:@"nd"]) {
		NSUInteger ref = [(NSString*)[attributeDict objectForKey:@"ref"] intValue]; 
		NSNumber* refAsNumber = [[NSNumber alloc] initWithUnsignedInteger:ref];
		[currentWay.nodesIds addObject:refAsNumber];
		[refAsNumber release];
	} else if ([elementName isEqual:@"tag"]) {
		if (tags==nil) {
			tags = [[NSMutableDictionary alloc] init];
			if (currentNode)
				currentNode.tags=tags;
			else if (currentWay)
				currentWay.tags=tags;
			else if (currentRelation)
				currentRelation.tags=tags;
		}
		[tags setObject:[attributeDict objectForKey:@"v"] forKey:[attributeDict objectForKey:@"k"]];
	} 
}

- (void)parser:(AQXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ([elementName isEqual:@"node"]) {
		if (isFirstNode) {
			isFirstNode=NO;
			if ([(NSObject*)delegate respondsToSelector:@selector(didStartParsingNodes)])
				[delegate didStartParsingNodes];
		}
		[delegate onNodeFound:currentNode];
		[currentNode release];
		currentNode = nil;
		[tags release];
		tags=nil;
	} else if ([elementName isEqual:@"way"]) {
		if (isFirstWay) {
			isFirstWay=NO;
			if ([(NSObject*)delegate respondsToSelector:@selector(didStartParsingWays)])
				[delegate didStartParsingWays];
		}
		[delegate onWayFound:currentWay];
		[currentWay release];
		currentWay=nil;
		[tags release];
		tags=nil;
	} else if ([elementName isEqual:@"relation"]) {
		if (isFirstRelation) {
			isFirstRelation=NO;
			[delegate didStartParsingRelations];
		}
		[delegate onRelationFound:currentRelation];
		[currentRelation release];
		currentRelation=nil;
		[tags release];
		tags=nil;
	}
}
*/

@end
