forge["media"] = {
   "playVideoURL": function (url, success, error) {
        forge.internal.call("media.playVideoURL", {
            url: url
        }, success, error);
   },

   "playVideoFile": function (file, success, error) {
        forge.internal.call("media.playVideoFile", {
            file: file
        }, success, error);
    },

    "playAudioFile": function (file, success, error) {
        forge.internal.call("media.playAudioFile", {
            file: file
        }, function (playerId) {
            success({
                play: function (success, error) {
                    forge.internal.call("media.audioPlayerPlay", { player: playerId }, success, error);
                },
                pause: function (success, error) {
                    forge.internal.call("media.audioPlayerPause", { player: playerId }, success, error);
                },
                stop: function (success, error) {
                    forge.internal.call("media.audioPlayerStop", { player: playerId }, success, error);
                },
                destroy: function (success, error) {
                    forge.internal.call("media.audioPlayerDestroy", { player: playerId }, success, error);
                },
                seek: function (seekTo, success, error) {
                    forge.internal.call("media.audioPlayerSeek", { player: playerId, seekTo: seekTo }, success, error);
                },
                duration: function (success, error) {
                    forge.internal.call("media.audioPlayerDuration", { player: playerId }, success, error);
                },
                positionChanged: {
                    addListener: function (callback, error) {
                        forge.internal.addEventListener("media.audioPlayer." + playerId + ".time", callback);
                    }
                }
            });
        }, error);
    }
};

// deprecations
forge["media"]["videoPlay"] = forge["media"]["playVideoURL"];
forge["media"]["createAudioPlayer"] = forge["media"]["playAudioFile"];
