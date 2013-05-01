//
//  Relation.h
//  OSMImporter
//
//  Created by y0n3l http://www.twitter.com/y0n3l on 1/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "Element.h"

@interface Member : NSObject{
	NSString* type;
	int64_t ref;
	NSString* role;
    Element * member;
}
@property (nonatomic, strong) NSString* type;
@property (nonatomic) int64_t ref;
@property (nonatomic, strong) NSString* role;
@property (nonatomic,strong)Element * member;

@end


@interface Relation : Element {
	NSMutableArray* members;
}

@property (nonatomic,strong)NSMutableArray* members;


@end
