/* global forge, $, asyncTest, askQuestion, ok, start */

module("forge.media");

forge.tools.getLocal("fixtures/media/test.mp3", function (audioFile) {
    forge.tools.getLocal("fixtures/media/small.mp4", function (videoFile) {
        testsWithFixtures(audioFile, videoFile);
    });
});

var testsWithFixtures = function (audioFile, videoFile) {
    asyncTest("Play audio", 1, function() {
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
        forge.media.videoPlay(videoFile);

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

        asyncTest("Gallery Video Player", 1, function() {
            forge.file.getVideo({
                source: "gallery"
            }, function (file) {
                forge.file.URL(file, function (url) {
                    forge.media.videoPlay(url, function () {
                        askQuestion("Did your video just play?", {
                            Yes: function () {
                                ok(true, "video capture successful");
                                start();
                            },
                            No: function () {
                                ok(false, "didn't play back just-captured video");
                                start();
                            }
                        });
                    }, function (e) {
                        ok(false, "API call failure: "+e.message);
                        start();
                    });
                }, function (e) {
                    ok(false, "API call failure: "+e.message);
                    start();
                });
            },	function (e) {
                ok(false, "API call failure: "+e.message);
                start();
            });
        });

    }
};
