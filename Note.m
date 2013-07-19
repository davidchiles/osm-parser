//
//  Note.m
//  OSM POI Editor
//
//  Created by David on 7/12/13.
//
//

#import "Note.h"

@implementation Note

@synthesize id,isOpen,commentsArray,coordinate,dateCreated,dateClosed;

-(id)init
{
    if (self = [super init]) {
        self.id = 0;
    }
    return self;
}

@end
