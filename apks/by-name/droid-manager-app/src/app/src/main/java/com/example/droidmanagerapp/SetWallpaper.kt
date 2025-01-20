package com.example.droidmanagerapp

import android.app.WallpaperManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.wallpaper.WallpaperService
import java.io.File

class SetWallpaper : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        try {
            val filePath = intent.getStringExtra("WALLPAPER_FILE") ?: return;
            val setHome = intent.getBooleanExtra("SET_HOME", false);
            val setLock = intent.getBooleanExtra("SET_LOCK", false);
            val fileStream = File(filePath).inputStream();
            val flags = (if (setHome) WallpaperManager.FLAG_SYSTEM else 0).
                or(if (setLock) WallpaperManager.FLAG_LOCK else 0);
            WallpaperManager.getInstance(context).setStream(fileStream, null, false, flags);
        } catch (e: Exception) {
            setResult(-1, e.message, Bundle());
        }
    }
}