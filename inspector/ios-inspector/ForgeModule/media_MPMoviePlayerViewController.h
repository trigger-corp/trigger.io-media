//
//  media_MPMoviePlayerViewController.h
//  Forge
//
//  Created by Connor Dunn on 28/05/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface media_MPMoviePlayerViewController : MPMoviePlayerViewController {
    
}

@property (readwrite, retain) ForgeTask *task; 

@end
