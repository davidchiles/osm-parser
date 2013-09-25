//
//  OSMXMLParserDelegate.m
//  OSM POI Editor
//
//  Created by David on 9/24/13.
//
//

#import "OSMXMLParserDelegate.h"

@implementation OSMXMLParserDelegate


-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    NSLog(@"Start Parsing");
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    NSLog(@"Found Element: %@",elementName);
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSLog(@"Finished Element: %@",elementName);
}

-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    NSLog(@"Ended Parsing");
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"Parser Error: %@",parseError);
}
-(void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    NSLog(@"Parser Validation Error: %@",validationError);
}
@end
