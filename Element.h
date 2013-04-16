//
//  Element.h
//  OSM POI Editor
//
//  Created by David on 4/16/13.
//
//

#import <Foundation/Foundation.h>

@interface Element : NSObject


@property (nonatomic,strong) NSDictionary * tags;
@property (nonatomic) int64_t elementID;

@end
