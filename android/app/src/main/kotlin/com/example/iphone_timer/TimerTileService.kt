package com.example.iphone_timer

import android.app.PendingIntent
import android.content.Intent
import android.service.quicksettings.TileService
import android.service.quicksettings.Tile
import android.os.Build

class TimerTileService : TileService() {

    override fun onTileAdded() {
        super.onTileAdded()
        updateTile()
    }

    override fun onStartListening() {
        super.onStartListening()
        updateTile()
    }

    override fun onClick() {
        super.onClick()

        // Use unlockAndRun to ensure proper execution
        unlockAndRun {
            launchApp()
        }
    }

    private fun launchApp() {
        try {
            // Method 1: Direct activity launch with PendingIntent (Android 14+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val intent = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                val pendingIntent = PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
                startActivityAndCollapse(pendingIntent)
                return
            }

            // Method 2: Direct activity launch (Android 7-13)
            val activityIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            startActivityAndCollapse(activityIntent)
        } catch (e: Exception) {
            e.printStackTrace()

            // Fallback: Use broadcast receiver
            try {
                val broadcastIntent = Intent(TileClickReceiver.ACTION_LAUNCH_APP).apply {
                    setPackage(packageName)
                }
                sendBroadcast(broadcastIntent)
            } catch (ex: Exception) {
                ex.printStackTrace()
            }
        }
    }

    private fun updateTile() {
        qsTile?.apply {
            state = Tile.STATE_ACTIVE
            label = "倒计时"
            updateTile()
        }
    }
}
