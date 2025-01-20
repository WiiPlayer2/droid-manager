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
            val fileStream = File(filePath).inputStream();
            WallpaperManager.getInstance(context).setStream(fileStream);
        } catch (e: Exception) {
            setResult(-1, e.message, Bundle());
        }
    }
}