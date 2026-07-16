package com.flowos.flowos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject

class FocusSessionForegroundService : Service() {
    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var job: Job? = null
    
    companion object {
        private const val CHANNEL_ID = "focus_session_channel"
        private const val NOTIFICATION_ID = 1001
        
        fun start(context: Context) {
            val intent = Intent(context, FocusSessionForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stop(context: Context) {
            val intent = Intent(context, FocusSessionForegroundService::class.java)
            context.stopService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification("Focus session active", "FlowOS is keeping your focus protected.")
        startForeground(NOTIFICATION_ID, notification)
        
        startLeaseRenewer()
        
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        job?.cancel()
        serviceScope.cancel()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Session Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the accessibility blocker active during focus sessions"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(title: String, text: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_secure) // Standard system secure lock icon
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun startLeaseRenewer() {
        job?.cancel()
        job = serviceScope.launch {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            while (isActive) {
                renewLease(prefs)
                delay(20000) // Renew lease every 20 seconds
            }
        }
    }

    private fun renewLease(prefs: SharedPreferences) {
        val activePoliciesJson = prefs.getString("flutter.flowos_active_policies", null)
        if (activePoliciesJson == null || activePoliciesJson.isEmpty()) {
            // No active policies, stop service
            stopSelf()
            return
        }

        try {
            val root = JSONObject(activePoliciesJson)
            val focus = root.optJSONObject("focus")
            if (focus == null) {
                // No active focus policy
                stopSelf()
                return
            }

            // Renew focus lease by updating activeUntil to now + 2 minutes
            val newActiveUntil = System.currentTimeMillis() + 120000L // 2 minutes in ms
            focus.put("activeUntil", newActiveUntil)
            
            // Write back to shared preferences
            prefs.edit().putString("flutter.flowos_active_policies", root.toString()).apply()
            
            // Update the notification text
            val mode = focus.optString("protectionMode", "focus")
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val notification = createNotification(
                "Focus session is running",
                "FlowOS is protecting your time. Protection level: ${mode.uppercase()}."
            )
            manager.notify(NOTIFICATION_ID, notification)
            
        } catch (e: Exception) {
            stopSelf()
        }
    }
}
