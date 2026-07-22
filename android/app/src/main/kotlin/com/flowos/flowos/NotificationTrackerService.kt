package com.flowos.flowos

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NotificationTrackerService : NotificationListenerService() {

    private val systemPackages = setOf(
        "android",
        "com.android.systemui",
        "com.google.android.gms",
        "com.google.android.gsf",
        "com.android.vending"
    )

    @Volatile
    private var cachedConsent: Boolean = false

    @Volatile
    private var lastConsentCheck: Long = 0L

    private fun isConsentEnabled(): Boolean {
        val now = System.currentTimeMillis()
        if (now - lastConsentCheck > 30000L) {
            try {
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                cachedConsent = prefs.getBoolean("flutter.flowos_interruption_collection_enabled", false)
                lastConsentCheck = now
            } catch (e: Exception) {
                android.util.Log.e("FlowOS", "Error checking interruption collection consent", e)
            }
        }
        return cachedConsent
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val packageName = sbn.packageName ?: return

        // Exclude our own package and system packages from interruption stats
        if (packageName == this.packageName || systemPackages.contains(packageName)) return

        if (!isConsentEnabled()) return

        val now = System.currentTimeMillis()
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val dayStr = sdf.format(Date(now))

        NotificationCountStore.recordNotification(this, packageName, dayStr)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Discard - we only track incoming notification interrupts
    }
}
