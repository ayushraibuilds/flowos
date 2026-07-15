package com.flowos.flowos

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

class FocusBlockerService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Don't block ourselves or system critical packages
        if (packageName == this.packageName) return
        if (isSystemCriticalPackage(packageName)) return

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // Read active policies set
        val activePoliciesJson = prefs.getString("flutter.flowos_active_policies", null) ?: return // Fail-open if absent
        
        val policies = try {
            JSONObject(activePoliciesJson)
        } catch (e: Exception) {
            return // Fail-open if unparseable
        }

        // Schema version check: must be 1
        val schemaVersion = policies.optInt("schemaVersion", 0)
        if (schemaVersion != 1) return // Fail-open if wrong version

        val focusPolicy = policies.optJSONObject("focus")
        val sleepPolicy = policies.optJSONObject("sleep")

        // Parse active policies
        val now = System.currentTimeMillis()
        var focusMode: String? = null
        var focusSessionId: String? = null
        var isFocusActive = false

        if (focusPolicy != null) {
            val sessionId = focusPolicy.optString("sessionId", "")
            val activeUntil = focusPolicy.optLong("activeUntil", 0L)
            val selectedPackages = focusPolicy.optJSONArray("selectedPackages")
            val protectionMode = focusPolicy.optString("protectionMode", "")

            if (sessionId.isNotEmpty() && activeUntil > 0 && selectedPackages != null && protectionMode.isNotEmpty()) {
                if (now <= activeUntil) {
                    val selectedPackagesSet = parseJsonArray(selectedPackages)
                    if (selectedPackagesSet.contains(packageName)) {
                        focusMode = protectionMode
                        focusSessionId = sessionId
                        isFocusActive = true
                    }
                }
            }
        }

        var sleepMode: String? = null
        var sleepSessionId: String? = null
        var isSleepActive = false

        if (sleepPolicy != null) {
            val sessionId = sleepPolicy.optString("sessionId", "")
            val activeUntil = sleepPolicy.optLong("activeUntil", 0L)
            val selectedPackages = sleepPolicy.optJSONArray("selectedPackages")
            val protectionMode = sleepPolicy.optString("protectionMode", "")

            if (sessionId.isNotEmpty() && activeUntil > 0 && selectedPackages != null && protectionMode.isNotEmpty()) {
                if (now <= activeUntil) {
                    val selectedPackagesSet = parseJsonArray(selectedPackages)
                    if (selectedPackagesSet.contains(packageName)) {
                        sleepMode = protectionMode
                        sleepSessionId = sessionId
                        isSleepActive = true
                    }
                }
            }
        }

        // If neither is protecting this package, we're done
        if (!isFocusActive && !isSleepActive) return

        // Resolve effective mode by stricter-wins
        // deep = 2, guard = 1, nudge = 0
        val focusVal = getStrictnessValue(focusMode)
        val sleepVal = getStrictnessValue(sleepMode)

        val (effectiveMode, activeSource, activeSessionId) = when {
            isFocusActive && isSleepActive -> {
                if (focusVal >= sleepVal) {
                    Triple(focusMode!!, "focus", focusSessionId!!)
                } else {
                    Triple(sleepMode!!, "sleep", sleepSessionId!!)
                }
            }
            isFocusActive -> Triple(focusMode!!, "focus", focusSessionId!!)
            else -> Triple(sleepMode!!, "sleep", sleepSessionId!!)
        }

        // Check scoped breaks
        // Verify focus breaks
        if (focusPolicy != null) {
            val focusBreaks = focusPolicy.optJSONArray("scopedBreaks")
            if (focusBreaks != null) {
                for (i in 0 until focusBreaks.length()) {
                    val b = focusBreaks.optJSONObject(i) ?: continue
                    if (b.optString("packageName") == packageName) {
                        val expiresAt = b.optLong("expiresAt", 0L)
                        if (now <= expiresAt) {
                            // Focus scoped break is active for this app.
                            // But wait: if sleep is active and has a stricter mode (e.g. Deep sleep),
                            // focus break cannot override sleep deep mode.
                            if (isSleepActive && getStrictnessValue(sleepMode) > getStrictnessValue(focusMode)) {
                                // Sleep wins (stricter), scoped break is ignored
                            } else {
                                return // App allowed through
                            }
                        }
                    }
                }
            }
        }

        // Verify sleep breaks
        if (sleepPolicy != null) {
            val sleepBreaks = sleepPolicy.optJSONArray("scopedBreaks")
            if (sleepBreaks != null) {
                for (i in 0 until sleepBreaks.length()) {
                    val b = sleepBreaks.optJSONObject(i) ?: continue
                    if (b.optString("packageName") == packageName) {
                        val expiresAt = b.optLong("expiresAt", 0L)
                        if (now <= expiresAt) {
                            // Sleep scoped break is active
                            // If focus is active and is stricter, focus wins
                            if (isFocusActive && getStrictnessValue(focusMode) > getStrictnessValue(sleepMode)) {
                                // Focus wins, sleep break ignored
                            } else {
                                return // App allowed through
                            }
                        }
                    }
                }
            }
        }

        // Apply protection behavior
        if (effectiveMode == "nudge") {
            val appLabel = getAppName(packageName)
            NudgeStore.record(this, packageName, appLabel, now, activeSessionId, activeSource)
        } else {
            // Guard or Deep: Intercept and redirect to FlowOS shield page
            writePendingTrigger(prefs, packageName, now, activeSource)
            redirectUser(packageName)
        }
    }

    private fun getStrictnessValue(mode: String?): Int {
        return when (mode) {
            "deep" -> 2
            "guard" -> 1
            "nudge" -> 0
            else -> 0
        }
    }

    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            info.loadLabel(pm).toString()
        } catch (e: Exception) {
            packageName
        }
    }



    private fun writePendingTrigger(
        prefs: android.content.SharedPreferences,
        packageName: String,
        now: Long,
        source: String
    ) {
        val editor = prefs.edit()
        val currentTriggerJson = prefs.getString("flutter.flowos_pending_trigger", null)
        
        if (currentTriggerJson != null) {
            try {
                val current = JSONObject(currentTriggerJson)
                val currentPackage = current.optString("packageName")
                val triggeredAt = current.optLong("triggeredAt", 0L)
                val claimed = current.optBoolean("claimed", false)
                
                // If there's an unclaimed trigger for the same package that is < 60s old, do not rewrite
                if (currentPackage == packageName && !claimed && (now - triggeredAt < 60000)) {
                    return
                }
            } catch (e: Exception) {}
        }

        try {
            val trigger = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("packageName", packageName)
                put("triggeredAt", now)
                put("source", source)
                put("claimed", false)
            }
            editor.putString("flutter.flowos_pending_trigger", trigger.toString())
            editor.apply()
        } catch (e: Exception) {}
    }

    private fun redirectUser(packageName: String) {
        val launchIntent = packageManager.getLaunchIntentForPackage(this.packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("blocked_app_trigger", packageName)
        }
        if (launchIntent != null) {
            startActivity(launchIntent)
        }
    }

    private fun parseJsonArray(array: JSONArray?): Set<String> {
        if (array == null) return emptySet()
        val set = mutableSetOf<String>()
        for (i in 0 until array.length()) {
            set.add(array.optString(i))
        }
        return set
    }

    private fun isSystemCriticalPackage(pkg: String): Boolean {
        val systemCritical = setOf(
            "com.android.phone",
            "com.android.server.telecom",
            "com.google.android.dialer",
            "com.android.emergency",
            "com.android.settings",
            "com.android.systemui",
            "com.android.launcher",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
            "com.sec.android.app.launcher",
            "com.huawei.android.launcher",
            "com.oppo.launcher",
            "com.miui.home"
        )
        return systemCritical.contains(pkg) || pkg.endsWith(".launcher") || pkg.contains("telephony")
    }

    override fun onInterrupt() {}
}
