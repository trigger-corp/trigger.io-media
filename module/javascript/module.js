forge['media'] = {
	'videoPlay': function (video, success, error) {
		if (!video.uri) {
			video = {
				uri: video
			};
		}
		forge.internal.call("media.videoPlay", video, success, error);
	},
	'createAudioPlayer': function (file, success, error) {
		forge.internal.call("media.createAudioPlayer", {file: file}, function (playerId) {
			success({
				play: function (success, error) {
					forge.internal.call("media.audioPlayerPlay", {player: playerId}, success, error);
				},
				pause: function (success, error) {
					forge.internal.call("media.audioPlayerPause", {player: playerId}, success, error);
				},
				stop: function (success, error) {
					forge.internal.call("media.audioPlayerStop", {player: playerId}, success, error);
				},
				destroy: function (success, error) {
					forge.internal.call("media.audioPlayerDestroy", {player: playerId}, success, error);
				},
				seek: function (seekTo, success, error) {
					forge.internal.call("media.audioPlayerSeek", {player: playerId, seekTo: seekTo}, success, error);
				},
				duration: function (success, error) {
					forge.internal.call("media.audioPlayerDuration", {player: playerId}, success, error);
				},
				positionChanged: {
					addListener: function (callback, error) {
						forge.internal.addEventListener('media.audioPlayer.'+playerId+'.time', callback);
					}
				}
			});
		}, error);
	}
};
