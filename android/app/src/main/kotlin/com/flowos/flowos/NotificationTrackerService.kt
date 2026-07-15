package com.flowos.flowos

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NotificationTrackerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val packageName = sbn.packageName ?: return

        // Exclude our own package from stats
        if (packageName == this.packageName) return

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // System Notification Access is not consent. Check master toggled permission flag:
        val collectionEnabled = prefs.getBoolean("flutter.flowos_interruption_collection_enabled", false)
        if (!collectionEnabled) return

        val now = System.currentTimeMillis()
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val dayStr = sdf.format(Date(now))

        NotificationCountStore.recordNotification(this, packageName, dayStr)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Discard - we only track incoming notification interrupts
    }
}
