//
//  media_API.h
//  Forge
//
//  Created by Connor Dunn on 30/04/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface media_API : NSObject

+ (void)videoPlay:(ForgeTask*)task uri:(NSString*)uri;

@end
