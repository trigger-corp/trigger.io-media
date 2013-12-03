``media``: Media file playback
==============================

The ``forge.media`` namespace allows you to play video or audio using native players.

##Config options

Enable Background Audio
:   If this is `true` then audio players will continue to play even when the app is running in the background.

##API

!method: forge.media.videoPlay(url, success, error)
!param: url `string` URL to video
!param: success `function()` callback to be invoked when no errors occur
!description: Play a video file found at a URL, fullscreen on the device. The video formats that work vary from device to device - make sure to test codec support properly!
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

> ::Note:: To allow users to select or capture videos using their device you may use the [file module](/modules/file/current/docs/index.html).

!method: forge.media.createAudioPlayer(file, success, error)
!param: file `file`  File object created using [forge.file](/modules/file/current/docs/index.html) methods representing audio object
!param: success `function(player)` callback to be invoked when no errors occur (argument is a player object)
!description: Create a audio player object from a media file which can then be used to play the audio.
!platforms: iOS, Android
!param: error `function(content)` called with details of any error which may occur

> ::Warning:: For ``player.duration`` and ``player.seek`` to work properly on
Android, use 128kb/s constant bit-rate MP3 files.

The audio player object returned in the success callback has the
following methods, all of which take success and error callbacks in the
same manner as other Forge methods:

-  ``player.play(success, error)``: Begin (or resume) playing the audio
   file.
-  ``player.pause(success, error)``: Pause the playback of the file.
-  ``player.stop(success, error)``: Stop the playback of the file and
   release the audio system.
-  ``player.duration(success, error)``: Calls the success callback with
   the duration of the audio in seconds.
-  ``player.seek(seekTo, success, error)``: Seek to the given time (in
   seconds) in the audio file, if the file is playing it will continue
   to play after seeking.
-  ``player.positionChanged.addListener(callback, error)``: Add a listener to be called when the playback position changes, will be called at most once per second while the audio is playing, the callback will be called with the time in seconds of the current playback position.
-  ``player.destroy(success, error)``: Destroy and clean up any resources used by the native audio player.

**Example**:

    forge.file.getLocal("music.mp3", function (file) {
      forge.media.createAudioPlayer(file, function (player) {
        player.play();
      });
    });
