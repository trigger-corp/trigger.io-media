package io.trigger.forge.android.modules.media;

import java.util.HashSet;
import java.util.Hashtable;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Map.Entry;

import android.media.MediaPlayer;
import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeEventListener;

public class EventListener extends ForgeEventListener {
	private HashSet<MediaPlayer> paused = new HashSet<MediaPlayer>();
	@Override
	public void onStop() {
		paused.clear();
		if (!ForgeApp.configForPlugin("media").has("enable_background_audio")
				|| !ForgeApp.configForPlugin("media").get("enable_background_audio").getAsBoolean()) {
			for (Entry<String, MediaPlayer> entry : API.mediaPlayers.entrySet()) {
				if (entry.getValue().isPlaying()) {
					paused.add(entry.getValue());
					entry.getValue().pause();
				}
			}
		}
	}
	
	@Override
	public void onDestroy() {
		for (Entry<String, TimerTask> entry : API.mediaPlayerTimerTask.entrySet()) {
			entry.getValue().cancel();
		}
		for (Entry<String, Timer> entry : API.mediaPlayerTimer.entrySet()) {
			entry.getValue().cancel();
		}
		for (Entry<String, MediaPlayer> entry : API.mediaPlayers.entrySet()) {
			entry.getValue().release();
		}
		API.mediaPlayers.clear();
		API.mediaPlayerTimer.clear();
		API.mediaPlayerRunnable.clear();
		API.mediaPlayerTimerTask.clear();
		API.mediaPlayerPrepared.clear();
	}
	
	@Override
	public void onStart() {
		for (MediaPlayer mediaPlayer : paused) {
			mediaPlayer.start();
		}
		paused.clear();
	}
}
