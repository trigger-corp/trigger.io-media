module("forge.media");

if (forge.is.mobile()) {
    asyncTest("Play audio", 1, function() {
        var audioFile = forge.inspector.getFixture('media', 'test.mp3');
        forge.media.createAudioPlayer(audioFile, function (player) {
            player.play(function () {
                askQuestion("Is audio playing?", {
                    Yes: function () {
                        player.duration(function (duration) {
                            player.seek(duration/3, function () {
                                askQuestion("Did the pitch jump?", {
                                    Yes: function () {
                                        player.positionChanged.addListener(function (time) {
                                            $('#playertime').text(time);
                                        });
                                        askQuestion("Is the time changing: <span id='playertime'></span>", {
                                            Yes: function () {
                                                player.pause(function () {
                                                    askQuestion("Has the audio paused?", {
                                                        Yes: function () {
                                                            player.play(function () {
                                                                askQuestion("Has the audio continued from where it paused?", {
                                                                    Yes: function () {
                                                                        player.stop(function () {
                                                                            askQuestion("Has the audio stopped?", {
                                                                                Yes: function () {
                                                                                    player.destroy(function () {
                                                                                        ok(true, "Success");
                                                                                        start();
                                                                                    }, function () {
                                                                                        ok(false, "Error calling destroy on player");
                                                                                        start();
                                                                                    });
                                                                                },
                                                                                No: function () {
                                                                                    ok(false, "User claims failure");
                                                                                    start();
                                                                                }
                                                                            });
                                                                        }, function () {
                                                                            ok(false, "Error calling stop on player");
                                                                            start();
                                                                        });
                                                                    },
                                                                    No: function () {
                                                                        ok(false, "User claims failure");
                                                                        start();
                                                                    }
                                                                });
                                                            }, function () {
                                                                ok(false, "Error calling play on player");
                                                                start();
                                                            });
                                                        },
                                                        No: function () {
                                                            ok(false, "User claims failure");
                                                            start();
                                                        }
                                                    });
                                                }, function () {
                                                    ok(false, "Error calling pause on player");
                                                    start();
                                                });
                                            },
                                            No: function () {
                                                ok(false, "User claims failure");
                                                start();
                                            }
                                        });
                                    },
                                    No: function () {
                                        ok(false, "User claims failure");
                                        start();
                                    }
                                });
                            }, function () {
                                ok(false, "Error calling seek on player");
                                start();
                            });
                        }, function () {
                            ok(false, "Error calling duration on player");
                            start();
                        });

                    },
                    No: function () {
                        ok(false, "User claims failure");
                        start();
                    }
                });
            }, function () {
                ok(false, "Error calling play on player");
                start();
            });
        }, function () {
            ok(false, "Error creating audio player");
                start();
        });
    });

    asyncTest("Play remote video", 1, function() {
        forge.media.videoPlay("https://ops.trigger.io/75d92dce/tests/big_buck_bunny.mp4");

        askQuestion("Did a video just play?", {
            Yes: function () {
                ok(true, "Success");
                start();
            },
            No: function () {
                ok(false, "User claims failure");
                start();
            }
        });
    });

    asyncTest("Play local video in assets", 1, function() {
        forge.media.videoPlay(forge.inspector.getFixture("media", "small.mp4").uri);

        askQuestion("Did another video just play?", {
            Yes: function () {
                ok(true, "Success");
                start();
            },
            No: function () {
                ok(false, "User claims failure");
                start();
            }
        });
    });

    if (forge.file) {
        asyncTest("Play local video", 1, function() {
            forge.file.getVideo(function (video) {
                forge.file.URL(video, function (url) {
                    askQuestion("Were you just prompted to select a video?", {
                        Yes: function () {
                            forge.media.videoPlay(url);
                            askQuestion("Did that video play?", {
                                Yes: function () {
                                    ok(true, "Success");
                                    start();
                                },
                                No: function () {
                                    ok(false, "User claims failure");
                                    start();
                                }
                            });
                        },
                        No: function () {
                            ok(false, "User claims failure");
                            start();
                        }
                    });
                });
            });
        });
    }
}
