package com.flowos.flowos

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

object NotificationCountStore {
    private val lock = Any()

    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_PENDING = "flutter.flowos_pending_notifications"
    private const val KEY_INFLIGHT = "flutter.flowos_inflight_notifications"
    private const val KEY_UNACKED = "flutter.flowos_unacked_batches"

    fun recordNotification(context: Context, packageName: String, dayStr: String) = synchronized(lock) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val pendingStr = prefs.getString(KEY_PENDING, "{}") ?: "{}"
        try {
            val root = JSONObject(pendingStr)
            val dayObj = root.optJSONObject(dayStr) ?: JSONObject()
            val count = dayObj.optInt(packageName, 0)
            dayObj.put(packageName, count + 1)
            root.put(dayStr, dayObj)
            prefs.edit().putString(KEY_PENDING, root.toString()).commit()
        } catch (e: Exception) {
            // Fail-safe
        }
    }

    fun startInFlightBatch(context: Context): String? = synchronized(lock) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val pendingStr = prefs.getString(KEY_PENDING, "{}") ?: "{}"
        if (pendingStr == "{}" || pendingStr.isEmpty()) return null

        val batchId = UUID.randomUUID().toString()
        try {
            val pendingObj = JSONObject(pendingStr)
            if (pendingObj.length() == 0) return null

            // Move active data to in-flight store
            val inflightStr = prefs.getString(KEY_INFLIGHT, "{}") ?: "{}"
            val inflightObj = JSONObject(inflightStr)
            inflightObj.put(batchId, pendingObj)

            // Append batch ID to unacked list
            val unackedStr = prefs.getString(KEY_UNACKED, "[]") ?: "[]"
            val unackedArr = JSONArray(unackedStr)
            unackedArr.put(batchId)

            val editor = prefs.edit()
            editor.putString(KEY_INFLIGHT, inflightObj.toString())
            editor.putString(KEY_UNACKED, unackedArr.toString())
            editor.putString(KEY_PENDING, "{}")
            editor.commit()

            // Return the batch package
            val batchPkg = JSONObject().apply {
                put("batchId", batchId)
                put("data", pendingObj)
            }
            return batchPkg.toString()
        } catch (e: Exception) {
            return null
        }
    }

    fun acknowledgeBatch(context: Context, batchId: String) = synchronized(lock) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        try {
            val inflightStr = prefs.getString(KEY_INFLIGHT, "{}") ?: "{}"
            val inflightObj = JSONObject(inflightStr)
            if (inflightObj.has(batchId)) {
                inflightObj.remove(batchId)
            }

            val unackedStr = prefs.getString(KEY_UNACKED, "[]") ?: "[]"
            val unackedArr = JSONArray(unackedStr)
            val newUnackedArr = JSONArray()
            for (i in 0 until unackedArr.length()) {
                val id = unackedArr.optString(i)
                if (id != batchId) {
                    newUnackedArr.put(id)
                }
            }

            val editor = prefs.edit()
            editor.putString(KEY_INFLIGHT, inflightObj.toString())
            editor.putString(KEY_UNACKED, newUnackedArr.toString())
            editor.commit()
        } catch (e: Exception) {
            // Fail-safe
        }
    }

    fun getUnacknowledgedBatches(context: Context): Map<String, String> = synchronized(lock) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val result = mutableMapOf<String, String>()
        try {
            val unackedStr = prefs.getString(KEY_UNACKED, "[]") ?: "[]"
            val unackedArr = JSONArray(unackedStr)
            val inflightStr = prefs.getString(KEY_INFLIGHT, "{}") ?: "{}"
            val inflightObj = JSONObject(inflightStr)

            for (i in 0 until unackedArr.length()) {
                val batchId = unackedArr.optString(i)
                val batchData = inflightObj.optJSONObject(batchId)
                if (batchData != null) {
                    result[batchId] = batchData.toString()
                }
            }
        } catch (e: Exception) {
            // Fail-safe
        }
        return result
    }

    fun wipeAll(context: Context) = synchronized(lock) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .remove(KEY_PENDING)
            .remove(KEY_INFLIGHT)
            .remove(KEY_UNACKED)
            .commit()
    }
}
