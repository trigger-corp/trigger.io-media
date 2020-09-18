//
//  media_API.m
//  Forge
//
//  Created by Connor Dunn on 30/04/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "media_API.h"
#import "media_AVPlayerViewController.h"

typedef void (^media_TimerBlock)(NSTimeInterval time);

static NSMutableDictionary *audioPlayers;

@implementation media_API


+ (void)playVideoFile:(ForgeTask*)task file:(NSDictionary*)file {
    NSError *error = nil;
    ForgeFile *forgeFile = [ForgeFile withScriptObject:file error:&error];
    if (error != nil) {
        return [task error:error.localizedDescription type:@"EXPECTED_FAILURE" subtype:nil];
    }
    
    NSURL *url = [ForgeStorage nativeURL:forgeFile];
    
    [media_API playVideoURL:task url:url.absoluteString];
}


+ (void)playVideoURL:(ForgeTask*)task url:(NSString*)url {
    NSURL *parsedURL = [NSURL URLWithString:url];
    if (parsedURL == nil) {
        [task error:@"Failed to load video file" type:@"EXPECTED_FAILURE" subtype:nil];
        return;
    }
    
    AVPlayer *player = [AVPlayer playerWithURL:parsedURL];
    media_AVPlayerViewController *playerController = [[media_AVPlayerViewController alloc] init];
    playerController.player = player;
    playerController.task = task;
    
    // workaround for black screen on iOS 13 after closing view controller 
    if (@available(iOS 13.0, *)) {
        playerController.modalPresentationStyle = UIModalPresentationPopover;
    } else {
        playerController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[ForgeApp sharedApp] viewController] presentViewController:playerController animated:TRUE completion:^{
            [playerController.player play];
        }];
    });
}


+ (void)createAudioPlayer:(ForgeTask*)task file:(NSDictionary*)file {
    NSError *error = nil;
    ForgeFile *forgeFile = [ForgeFile withScriptObject:file error:&error];
    if (error != nil) {
        return [task error:error.localizedDescription type:@"EXPECTED_FAILURE" subtype:nil];
    }
    
    if (audioPlayers == nil) {
        audioPlayers = [[NSMutableDictionary alloc] init];
    }
    
    [forgeFile contents:^(NSData *data) {
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
