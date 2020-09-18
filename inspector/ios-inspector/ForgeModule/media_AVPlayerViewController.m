//
//  media_MPMoviePlayerViewController.m
//  Forge
//
//  Created by Connor Dunn on 28/05/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import "media_AVPlayerViewController.h"

@interface media_AVPlayerViewController ()

@end

@implementation media_AVPlayerViewController

@synthesize task;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.task) {
        [self.task success:nil];
        self.task = nil;
    }	
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return [[ForgeApp sharedApp].viewController prefersStatusBarHidden];
}

@end
