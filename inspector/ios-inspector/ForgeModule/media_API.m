//
//  media_API.m
//  Forge
//
//  Created by Connor Dunn on 30/04/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "media_API.h"
#import "media_MPMoviePlayerViewController.h"

typedef void (^media_TimerBlock)(NSTimeInterval time);

static NSMutableDictionary *audioPlayers;

@implementation media_API

+ (void)videoPlay:(ForgeTask*)task uri:(NSString*)uri {
	NSURL *url = [NSURL URLWithString:uri];
	media_MPMoviePlayerViewController *player;

	if ([[url scheme] isEqualToString:@"content"] && [[url host] isEqualToString:@"forge-content"]) {
		// Special Forge URI, get original URI to stream video.
		NSDictionary *file = [url queryAsDictionary];
		
		uri = [file objectForKey:@"uri"];
	}

	NSURL *assertUrl;
	if ([uri hasPrefix:@"/"]) {
		assertUrl = [NSURL fileURLWithPath:uri];
	} else {
		uri = [uri stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
		assertUrl = [NSURL URLWithString:uri];
	}
	
	player = [[media_MPMoviePlayerViewController alloc] initWithContentURL:assertUrl];
	
	player.task = task;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[[[ForgeApp sharedApp] viewController] presentMoviePlayerViewControllerAnimated:player];
	});
}

+ (void)createAudioPlayer:(ForgeTask*)task file:(NSObject*)file {
	if (audioPlayers == nil) {
		audioPlayers = [[NSMutableDictionary alloc] init];
	}
	
	ForgeFile *forgeFile = [[ForgeFile alloc] initWithObject:file];
	[forgeFile data:^(NSData *data) {
		if (!data) {
			[task error:@"Failed to load audio file" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}
		NSError *error = nil;
		AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
		if (error) {
			[task error:@"Failed to load audio file" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}
		
		// Required to play in background
        if([[[[ForgeApp sharedApp] configForModule:@"media"] objectForKey:@"enable_background_audio"] boolValue]){
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
        } else {
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&error];
        }

		[audioPlayers setObject:[NSMutableDictionary dictionaryWithDictionary:@{@"player": audioPlayer}] forKey:[task callid]];
		[task success:[task callid]];
	} errorBlock:^(NSError *error) {
		[task error:@"Failed to load audio file" type:@"EXPECTED_FAILURE" subtype:nil];
	}];
}

+ (void)audioPlayerPlay:(ForgeTask*)task player:(NSString*)playerID {
	AVAudioPlayer *audioPlayer = [[audioPlayers objectForKey:playerID] objectForKey:@"player"];
	if (audioPlayer) {
		[audioPlayer play];
		media_TimerBlock block = ^(NSTimeInterval time) {
			if ([audioPlayer currentTime] == 0) {
				[[[audioPlayers objectForKey:playerID] objectForKey:@"timer"] invalidate];
				[[ForgeApp sharedApp] event:[NSString stringWithFormat:@"media.audioPlayer.%@.time", playerID, nil] withParam:@{@"time": [NSNumber numberWithDouble:[audioPlayer duration]]}];
			} else {
				[[ForgeApp sharedApp] event:[NSString stringWithFormat:@"media.audioPlayer.%@.time", playerID, nil] withParam:@{@"time": [NSNumber numberWithDouble:[audioPlayer currentTime]]}];
			}
		};
		NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector: @selector(executeBlockFromTimer:) userInfo:[block copy] repeats:YES];
		[[audioPlayers objectForKey:playerID] setObject:timer forKey:@"timer"];
		[task success:nil];
	} else {
		[task error:@"Audio player no longer exists" type:@"EXPECTED_FAILURE" subtype:nil];
	}
}

+ (void)audioPlayerPause:(ForgeTask*)task player:(NSString*)playerID {
	AVAudioPlayer *audioPlayer = [[audioPlayers objectForKey:playerID] objectForKey:@"player"];
	if (audioPlayer) {
		[audioPlayer pause];
		if ([[audioPlayers objectForKey:playerID] objectForKey:@"timer"]) {
			[[[audioPlayers objectForKey:playerID] objectForKey:@"timer"] invalidate];
		}
		[task success:nil];
	} else {
		[task error:@"Audio player no longer exists" type:@"EXPECTED_FAILURE" subtype:nil];
	}
}

+ (void)audioPlayerStop:(ForgeTask*)task player:(NSString*)playerID {
	AVAudioPlayer *audioPlayer = [[audioPlayers objectForKey:playerID] objectForKey:@"player"];
	if (audioPlayer) {
		[audioPlayer stop];
		if ([[audioPlayers objectForKey:playerID] objectForKey:@"timer"]) {
			[[[audioPlayers objectForKey:playerID] objectForKey:@"timer"] invalidate];
		}
		[task success:nil];
	} else {
		[task error:@"Audio player no longer exists" type:@"EXPECTED_FAILURE" subtype:nil];
	}
}

+ (void)audioPlayerDuration:(ForgeTask*)task player:(NSString*)playerID {
	AVAudioPlayer *audioPlayer = [[audioPlayers objectForKey:playerID] objectForKey:@"player"];
	if (audioPlayer) {
		[task success:[NSNumber numberWithDouble:[audioPlayer duration]]];
	} else {
		[task error:@"Audio player no longer exists" type:@"EXPECTED_FAILURE" subtype:nil];
	}
}

+ (void)audioPlayerSeek:(ForgeTask*)task player:(NSString*)playerID seekTo:(NSNumber*)seekTo {
	AVAudioPlayer *audioPlayer = [[audioPlayers objectForKey:playerID] objectForKey:@"player"];
	if (audioPlayer) {
		BOOL playing = [audioPlayer isPlaying];
		[audioPlayer stop];
		if ([[audioPlayers objectForKey:playerID] objectForKey:@"timer"]) {
			[[[audioPlayers objectForKey:playerID] objectForKey:@"timer"] invalidate];
		}
		[audioPlayer setCurrentTime:[seekTo doubleValue]];
		if (playing) {
			[audioPlayer play];
			media_TimerBlock block = ^(NSTimeInterval time) {
				if ([audioPlayer currentTime] == 0) {
					[[[audioPlayers objectForKey:playerID] objectForKey:@"timer"] invalidate];
					[[ForgeApp sharedApp] event:[NSString stringWithFormat:@"media.audioPlayer.%@.time", playerID, nil] withParam:[NSNumber numberWithDouble:[audioPlayer duration]]];
				} else {
					[[ForgeApp sharedApp] event:[NSString stringWithFormat:@"media.audioPlayer.%@.time", playerID, nil] withParam:[NSNumber numberWithDouble:[audioPlayer currentTime]]];
				}
			};
			NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector: @selector(executeBlockFromTimer:) userInfo:[block copy] repeats:YES];
			[[audioPlayers objectForKey:playerID] setObject:timer forKey:@"timer"];
		}
		[task success:nil];
	} else {
		[task error:@"Audio player no longer exists" type:@"EXPECTED_FAILURE" subtype:nil];
	}
}

+ (void)audioPlayerDestroy:(ForgeTask*)task player:(NSString*)playerID {
	if ([[audioPlayers objectForKey:playerID] objectForKey:@"timer"]) {
		[[[audioPlayers objectForKey:playerID] objectForKey:@"timer"] invalidate];
	}
	[audioPlayers removeObjectForKey:playerID];
	[task success:nil];
}

+ (void)executeBlockFromTimer:(NSTimer *)aTimer {
	NSTimeInterval time = [aTimer timeInterval];
	media_TimerBlock block = [aTimer userInfo];
	if (block) block(time);
}

@end