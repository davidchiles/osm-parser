//
//  Element.m
//  OSM POI Editor
//
//  Created by David on 4/16/13.
//
//

#import "Element.h"

@implementation Element

@synthesize uid,user,action,version,changeset,elementID;

-(id)init
{
    if(self = [super init])
    {
        self.tags = [NSMutableDictionary dictionary];
    }
    return self;
}

-(id)initWithDictionary:(NSDictionary *)dictionary
{
    if(self = [self init])
    {
        [self addMetaData:dictionary];
    }
    return self;
}

-(void)addMetaData:(NSDictionary *)dictionary
{
    self.elementID = [[dictionary objectForKey:@"id"] longLongValue];
    self.uid = [[dictionary objectForKey:@"uid"] longLongValue];
    self.user = [dictionary objectForKey:@"user"];
    self.version = [[dictionary objectForKey:@"version"] longLongValue];
    self.changeset = [[dictionary objectForKey:@"changeset"] longLongValue];
    
    [self addDateWithString:[dictionary objectForKey:@"timestamp"]];
}
-(NSString *)formattedDate
{
    NSDateFormatter * dateFormatter = [self defaultDateFormatter];
    return [dateFormatter stringFromDate:self.timeStamp];

}
-(void)addDateWithString:(NSString *)dateString
{
    NSDateFormatter * dateFormatter = [self defaultDateFormatter];
    self.timeStamp = [dateFormatter dateFromString:dateString];

}
-(NSDateFormatter *)defaultDateFormatter
{
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ssZ"];
    return formatter;
}
-(NSString *)tableName
{
    return @"";
}
-(NSString *)tagsTableName
{
    return @"";
}

@end
