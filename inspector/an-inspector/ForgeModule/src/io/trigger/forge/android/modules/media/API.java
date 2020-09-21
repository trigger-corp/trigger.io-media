package io.trigger.forge.android.modules.media;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.res.AssetFileDescriptor;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;

import androidx.core.content.FileProvider;

import com.google.common.base.Throwables;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;
import com.llamalab.safs.Path;
import com.llamalab.safs.Paths;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.util.Hashtable;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeFile;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeParam;
import io.trigger.forge.android.core.ForgeStorage;
import io.trigger.forge.android.core.ForgeTask;


public class API {
    protected static Hashtable<String, MediaPlayer> mediaPlayers = new Hashtable<String, MediaPlayer>();
    protected static Hashtable<String, Timer> mediaPlayerTimer = new Hashtable<String, Timer>();
    protected static Hashtable<String, Runnable> mediaPlayerRunnable = new Hashtable<String, Runnable>();
    protected static Hashtable<String, TimerTask> mediaPlayerTimerTask = new Hashtable<String, TimerTask>();
    protected static Hashtable<String, Boolean> mediaPlayerPrepared = new Hashtable<String, Boolean>();

    public static void playVideoFile(final ForgeTask task, @ForgeParam("file") final JsonObject file) {
        Intent intent = new Intent(Intent.ACTION_VIEW);

        ForgeFile forgeFile = new ForgeFile(file);
        URL nativeURL = ForgeStorage.getNativeURL(forgeFile);

        Context context = ForgeApp.getActivity();

        if (forgeFile.getEndpointId() == ForgeStorage.EndpointId.Source) {
            // handle /src directory differently because ForgeFileProvider can't serve assets directory
            String authority = context.getPackageName();
            Path path = Paths.get(nativeURL.getPath());
            path = Paths.get("/" + authority).relativize(path);
            Uri contentUri = (new Uri.Builder()).scheme("content")
                    .authority(authority)
                    .path(path.toString())
                    .build();
            intent.setDataAndType(contentUri, "video/*");

        } else {
            // See: https://developer.android.com/reference/androidx/core/content/FileProvider
            Uri contentUri;
            try {
                String authority = context.getPackageName() + ".ForgeFileProvider";
                File nativeFile = new File(nativeURL.getFile());
                contentUri = FileProvider.getUriForFile(context, authority, nativeFile);
            } catch (IllegalArgumentException e) {
                task.error("Failed to load video file: " + forgeFile.toString(), "EXPECTED_FAILURE", null);
                return;
            }
            intent.setDataAndType(contentUri, "video/*");
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            List<ResolveInfo> resInfoList = context.getPackageManager().queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);
            for (ResolveInfo resolveInfo : resInfoList) {
                context.grantUriPermission(resolveInfo.activityInfo.packageName,
                        contentUri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
            }
        }

        ForgeApp.getActivity().addResumeCallback(new Runnable() {
            public void run() {
                // Call success when the webview is back in focus.
                task.success();
            }
        });

        ForgeApp.getActivity().startActivity(intent);
    }


    public static void playVideoURL(final ForgeTask task, @ForgeParam("url") final String url) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(Uri.parse(url), "video/*");
        ForgeApp.getActivity().startActivity(intent);
        ForgeApp.getActivity().addResumeCallback(new Runnable() {
            public void run() {
                // Call success when the webview is back in focus.
                task.success();
            }
        });
    }


    public static void playAudioFile(final ForgeTask task, @ForgeParam("file") final JsonObject file) {
        final MediaPlayer mediaPlayer = new MediaPlayer();
        mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);

        try {
            ForgeFile forgeFile = new ForgeFile(file);
            AssetFileDescriptor descriptor = ForgeStorage.getFileDescriptor(forgeFile);
            mediaPlayer.setDataSource(descriptor.getFileDescriptor(), descriptor.getStartOffset(), descriptor.getLength());
            mediaPlayer.prepare();
            mediaPlayers.put(task.callid, mediaPlayer);
            mediaPlayerPrepared.put(task.callid, true);
            final Timer timer = new Timer();
            mediaPlayerTimer.put(task.callid, timer);

            mediaPlayerRunnable.put(task.callid, new Runnable() {
                @Override
                public void run() {
                    if (!mediaPlayer.isPlaying()) {
                        ForgeApp.event("media.audioPlayer."+task.callid+".time", new JsonPrimitive((float)mediaPlayer.getDuration()/1000));
                        mediaPlayerTimerTask.get(task.callid).cancel();
                    } else {
                        ForgeApp.event("media.audioPlayer."+task.callid+".time", new JsonPrimitive((float)mediaPlayer.getCurrentPosition()/1000));
                    }
                }
            });

            task.success(task.callid);

        } catch (IOException e) {
            ForgeLog.w(Throwables.getStackTraceAsString(e));
            task.error("Failed to load audio file", "EXPECTED_FAILURE", null);
        }
    }

    public static void audioPlayerPlay(final ForgeTask task, @ForgeParam("player") final String playerId) {
        if (mediaPlayers.containsKey(playerId)) {
            if (!mediaPlayerPrepared.get(playerId)) {
                try {
                    mediaPlayers.get(playerId).prepare();
                    mediaPlayerPrepared.put(playerId, true);
                } catch (IOException e) {
                    task.error("Failed to load audio file", "EXPECTED_FAILURE", null);
                }
            }
            mediaPlayers.get(playerId).start();
            TimerTask timerTask = new TimerTask() {
                @Override
                public void run() {
                    mediaPlayerRunnable.get(playerId).run();
                }
            };
            if (mediaPlayerTimerTask.containsKey(playerId)) {
                mediaPlayerTimerTask.get(playerId).cancel();
            }
            mediaPlayerTimerTask.put(playerId, timerTask);
            mediaPlayerTimer.get(playerId).scheduleAtFixedRate(timerTask, 0, 1000);
            task.success();
        } else {
            task.error("Audio player no longer exists", "EXPECTED_FAILURE", null);
        }
    }

    public static void audioPlayerPause(final ForgeTask task, @ForgeParam("player") final String playerId) {
        if (mediaPlayers.containsKey(playerId)) {
            if (mediaPlayers.get(playerId).isPlaying()) {
                mediaPlayers.get(playerId).pause();
                mediaPlayerTimerTask.get(playerId).cancel();
            }
            task.success();
        } else {
            task.error("Audio player no longer exists", "EXPECTED_FAILURE", null);
        }
    }

    public static void audioPlayerStop(final ForgeTask task, @ForgeParam("player") final String playerId) {
        if (mediaPlayers.containsKey(playerId)) {
            mediaPlayers.get(playerId).stop();
            if (mediaPlayerTimerTask.containsKey(playerId)) {
                mediaPlayerTimerTask.get(playerId).cancel();
            }
            mediaPlayerPrepared.put(playerId, false);
            task.success();
        } else {
            task.error("Audio player no longer exists", "EXPECTED_FAILURE", null);
        }
    }

    public static void audioPlayerDuration(final ForgeTask task, @ForgeParam("player") final String playerId) {
        if (mediaPlayers.containsKey(playerId)) {
            task.success(new JsonPrimitive(((double)mediaPlayers.get(playerId).getDuration())/1000));
        } else {
            task.error("Audio player no longer exists", "EXPECTED_FAILURE", null);
        }
    }

    public static void audioPlayerSeek(final ForgeTask task, @ForgeParam("player") final String playerId, @ForgeParam("seekTo") final double seekTo) {
        if (mediaPlayers.containsKey(playerId)) {
            if (!mediaPlayerPrepared.get(playerId)) {
                try {
                    mediaPlayers.get(playerId).prepare();
                    mediaPlayerPrepared.put(playerId, true);
                } catch (IOException e) {
                    task.error("Failed to load audio file", "EXPECTED_FAILURE", null);
                }
            }
            mediaPlayers.get(playerId).seekTo((int) (seekTo*1000));
            task.success();
        } else {
            task.error("Audio player no longer exists", "EXPECTED_FAILURE", null);
        }
    }

    public static void audioPlayerDestroy(final ForgeTask task, @ForgeParam("player") final String playerId) {
        if (mediaPlayers.containsKey(playerId)) {
            mediaPlayers.get(playerId).stop();
            mediaPlayers.remove(playerId);
            mediaPlayerPrepared.remove(playerId);
        }
        if (mediaPlayerTimerTask.containsKey(playerId)) {
            mediaPlayerTimerTask.get(playerId).cancel();
            mediaPlayerTimerTask.remove(playerId);
        }
        if (mediaPlayerTimer.containsKey(playerId)) {
            mediaPlayerTimer.get(playerId).cancel();
            mediaPlayerTimer.remove(playerId);
        }
        if (mediaPlayerRunnable.containsKey(playerId)) {
            mediaPlayerRunnable.remove(playerId);
        }
        task.success();
    }
}
