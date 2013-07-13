//
//  Comment.h
//  OSM POI Editor
//
//  Created by David on 7/12/13.
//
//

#import <Foundation/Foundation.h>

@interface Comment : NSObject

@property (nonatomic,strong) NSDate * date;
@property (nonatomic,strong) NSString * text;
@property (nonatomic,strong) NSString * username;
@property (nonatomic) int64_t userID;

@end