package com.example.iphone_timer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class TileClickReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_LAUNCH_APP) {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            context.startActivity(launchIntent)
        }
    }

    companion object {
        const val ACTION_LAUNCH_APP = "com.example.iphone_timer.LAUNCH_APP"
    }
}
