package com.flowos.flowos

import android.content.Context
import org.json.JSONObject
import java.util.UUID

object TriggerStore {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_PENDING_TRIGGER = "flutter.flowos_pending_trigger"
    private const val EXPIRY_MS = 60000L
    private const val DEBOUNCE_MS = 1500L // package debounce
    private const val REDIRECT_RATE_LIMIT_MS = 2000L // redirect rate limit

    @Volatile
    private var lastRedirectTime = 0L

    @Volatile
    private var lastTriggeredPackage: String? = null

    @Volatile
    private var lastTriggeredTime = 0L

    @Synchronized
    fun writeTrigger(context: Context, packageName: String, now: Long, source: String, bypassAllowed: Boolean): Boolean {
        // Debounce package triggers to prevent multiple rapid triggers of the same app
        if (packageName == lastTriggeredPackage && (now - lastTriggeredTime < DEBOUNCE_MS)) {
            return false
        }

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val currentTriggerJson = prefs.getString(KEY_PENDING_TRIGGER, null)

        if (currentTriggerJson != null) {
            try {
                val current = JSONObject(currentTriggerJson)
                val currentPackage = current.optString("packageName")
                val triggeredAt = current.optLong("triggeredAt", 0L)
                val claimed = current.optBoolean("claimed", false)

                // If there's an unclaimed trigger for the same package that is still valid (< 60s), do not overwrite
                if (currentPackage == packageName && !claimed && (now - triggeredAt < EXPIRY_MS)) {
                    return false
                }
            } catch (e: Exception) {}
        }

        // Apply redirect rate limiting
        if (now - lastRedirectTime < REDIRECT_RATE_LIMIT_MS) {
            return false
        }

        try {
            val trigger = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("packageName", packageName)
                put("triggeredAt", now)
                put("source", source)
                put("claimed", false)
                put("bypassAllowed", bypassAllowed)
            }
            // Use synchronous commit() to guarantee atomicity for cross-process claim/write transitions
            val success = prefs.edit().putString(KEY_PENDING_TRIGGER, trigger.toString()).commit()
            if (success) {
                lastTriggeredPackage = packageName
                lastTriggeredTime = now
                lastRedirectTime = now
                return true
            }
        } catch (e: Exception) {}
        return false
    }

    @Synchronized
    fun claimTrigger(context: Context, now: Long): Map<String, Any>? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val triggerStr = prefs.getString(KEY_PENDING_TRIGGER, null) ?: return null
        try {
            val trigger = JSONObject(triggerStr)
            val id = trigger.optString("id")
            val packageName = trigger.optString("packageName")
            val triggeredAt = trigger.optLong("triggeredAt", 0L)
            val claimed = trigger.optBoolean("claimed", false)
            val source = trigger.optString("source", "focus")
            val bypassAllowed = trigger.optBoolean("bypassAllowed", true)

            if (!claimed && (now - triggeredAt < EXPIRY_MS)) {
                trigger.put("claimed", true)
                prefs.edit().putString(KEY_PENDING_TRIGGER, trigger.toString()).commit()

                return mapOf(
                    "id" to id,
                    "packageName" to packageName,
                    "triggeredAt" to triggeredAt,
                    "source" to source,
                    "claimed" to true,
                    "bypassAllowed" to bypassAllowed
                )
            }
        } catch (e: Exception) {}
        return null
    }
}
