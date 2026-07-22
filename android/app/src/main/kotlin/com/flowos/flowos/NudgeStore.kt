package com.flowos.flowos

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

object NudgeStore {
    private val lock = Any()

    fun record(context: Context, packageName: String, appLabel: String, now: Long, sessionId: String, source: String) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val currentEventsJson = prefs.getString("flutter.flowos_nudge_events", "[]") ?: "[]"
            try {
                val array = JSONArray(currentEventsJson)
                val newArray = JSONArray()

                // 1. Filter out expired nudges (older than 10 minutes)
                for (i in 0 until array.length()) {
                    val e = array.optJSONObject(i) ?: continue
                    val expiresAt = e.optLong("expiresAt", 0L)
                    if (now <= expiresAt) {
                        newArray.put(e)
                    }
                }

                // 2. Cooldown check: only one unexpired nudge per package within 10 minutes (600,000 ms)
                for (i in 0 until newArray.length()) {
                    val e = newArray.optJSONObject(i) ?: continue
                    if (e.optString("packageName") == packageName) {
                        val occurredAt = e.optLong("occurredAt", 0L)
                        if (now - occurredAt < 600000) {
                            return // Skip writing duplicate nudge within cooldown (non-local return exits record)
                        }
                    }
                }

                val newEvent = JSONObject().apply {
                    put("id", UUID.randomUUID().toString())
                    put("kind", "nudge")
                    put("packageName", packageName)
                    put("appLabel", appLabel)
                    put("sessionId", sessionId)
                    put("source", source)
                    put("occurredAt", now)
                    put("expiresAt", now + 600000) // Expires in 10 minutes
                    put("claimed", false)
                }
                newArray.put(newEvent)
                prefs.edit().putString("flutter.flowos_nudge_events", newArray.toString()).commit()
            } catch (e: Exception) {
                android.util.Log.e("FlowOS", "Error recording nudge in NudgeStore", e)
            }
        }
    }

    fun claim(context: Context, now: Long): Map<String, Any>? {
        synchronized(lock) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val eventsStr = prefs.getString("flutter.flowos_nudge_events", "[]") ?: "[]"
            try {
                val array = JSONArray(eventsStr)
                val newArray = JSONArray()
                var claimedNudge: JSONObject? = null
                
                for (i in 0 until array.length()) {
                    val e = array.optJSONObject(i) ?: continue
                    val expiresAt = e.optLong("expiresAt", 0L)
                    val claimed = e.optBoolean("claimed", false)
                    
                    if (now <= expiresAt) {
                        if (!claimed && claimedNudge == null) {
                            e.put("claimed", true)
                            claimedNudge = e
                        }
                        newArray.put(e)
                    }
                }
                prefs.edit().putString("flutter.flowos_nudge_events", newArray.toString()).commit()
                
                if (claimedNudge != null) {
                    return mapOf(
                        "id" to claimedNudge.optString("id"),
                        "packageName" to claimedNudge.optString("packageName"),
                        "appLabel" to claimedNudge.optString("appLabel"),
                        "sessionId" to claimedNudge.optString("sessionId"),
                        "source" to claimedNudge.optString("source"),
                        "occurredAt" to claimedNudge.optLong("occurredAt"),
                        "expiresAt" to claimedNudge.optLong("expiresAt")
                    )
                }
            } catch (e: Exception) {
                android.util.Log.e("FlowOS", "Error claiming nudge in NudgeStore", e)
            }
            return null
        }
    }

    fun clearForSession(context: Context, sessionId: String) {
        synchronized(lock) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val eventsStr = prefs.getString("flutter.flowos_nudge_events", "[]") ?: "[]"
            try {
                val array = JSONArray(eventsStr)
                val newArray = JSONArray()
                for (i in 0 until array.length()) {
                    val e = array.optJSONObject(i) ?: continue
                    if (e.optString("sessionId") != sessionId) {
                        newArray.put(e)
                    }
                }
                prefs.edit().putString("flutter.flowos_nudge_events", newArray.toString()).commit()
            } catch (e: Exception) {
                android.util.Log.e("FlowOS", "Error clearing session nudges in NudgeStore", e)
            }
        }
    }
}
