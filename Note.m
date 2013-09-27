//
//  Note.m
//  OSM POI Editor
//
//  Created by David on 7/12/13.
//
//

#import "Note.h"
#import "Comment.h"

@implementation Note

@synthesize id,isOpen,commentsArray,coordinate,dateCreated,dateClosed;

-(id)init
{
    if (self = [super init]) {
        self.id = 0;
    }
    return self;
}


-(void)addComment:(Comment *)comment
{
    if ([self.commentsArray count]) {
        NSMutableArray * mutableComments = [self.commentsArray mutableCopy];
        [mutableComments addObject:comment];
        self.commentsArray = mutableComments;
    }
    else{
        self.commentsArray = @[comment];
    }
}
@end
