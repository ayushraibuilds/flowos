package com.flowos.flowos

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.provider.MediaStore
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.UUID

class FocusBlockerService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Don't block ourselves or system critical/essential packages resolved natively
        if (packageName == this.packageName) return
        if (isSystemCriticalPackage(packageName)) return

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()

        // 1. Evaluate Focus Policy
        val activePoliciesJson = prefs.getString("flutter.flowos_active_policies", null)
        val policies = try {
            if (activePoliciesJson != null) JSONObject(activePoliciesJson) else null
        } catch (e: Exception) {
            null
        }

        val focusPolicy = policies?.optJSONObject("focus")
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

        // 2. Evaluate Dynamic Sleep Policy
        val sleepPolicy = evaluateDynamicSleepPolicy(prefs, packageName, now)
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

        // Check Focus Scoped Breaks
        if (activeSource == "focus" && focusPolicy != null) {
            val focusBreaks = focusPolicy.optJSONArray("scopedBreaks")
            if (focusBreaks != null) {
                for (i in 0 until focusBreaks.length()) {
                    val b = focusBreaks.optJSONObject(i) ?: continue
                    if (b.optString("packageName") == packageName) {
                        val expiresAt = b.optLong("expiresAt", 0L)
                        if (now <= expiresAt) {
                            // Focus scoped break is active.
                            // But wait: if sleep is also active, is it stricter?
                            if (isSleepActive && sleepVal > focusVal) {
                                // Sleep overrides focus break because it's stricter
                            } else {
                                return // App allowed through (Focus break active and Sleep is not stricter)
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
            // For Focus Guard, bypass (timed breaks) is allowed. Sleep Guard does NOT allow timed breaks.
            val bypassAllowed = if (activeSource == "focus") (effectiveMode == "guard") else false
            writePendingTrigger(prefs, packageName, now, activeSource, bypassAllowed)
            redirectUser(packageName)
        }
    }

    private fun evaluateDynamicSleepPolicy(prefs: android.content.SharedPreferences, packageName: String, now: Long): JSONObject? {
        val configStr = prefs.getString("flutter.flowos_sleep_config", null) ?: return null
        try {
            val config = JSONObject(configStr)
            val enabled = config.optBoolean("enabled", false)
            if (!enabled) return null

            val bedtime = config.optInt("bedtimeMinute", -1)
            val wake = config.optInt("wakeMinute", -1)
            if (bedtime == -1 || wake == -1 || bedtime == wake) return null

            val weekdaysArr = config.optJSONArray("weekdays") ?: return null
            val weekdaysList = mutableSetOf<Int>()
            for (i in 0 until weekdaysArr.length()) {
                weekdaysList.add(weekdaysArr.optInt(i))
            }

            val selectedPackagesArr = config.optJSONArray("selectedPackages") ?: return null
            val selectedPackages = mutableSetOf<String>()
            for (i in 0 until selectedPackagesArr.length()) {
                selectedPackages.add(selectedPackagesArr.optString(i))
            }
            if (!selectedPackages.contains(packageName)) return null

            val protectionLevel = config.optString("protectionLevel", "guard")

            // Determine if current time falls in the sleep window
            val calendar = Calendar.getInstance().apply { timeInMillis = now }
            val currentDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
            // 1=Sun, 2=Mon ... 7=Sat. Map to 1=Mon ... 7=Sun
            val mappedToday = when (currentDayOfWeek) {
                Calendar.MONDAY -> 1
                Calendar.TUESDAY -> 2
                Calendar.WEDNESDAY -> 3
                Calendar.THURSDAY -> 4
                Calendar.FRIDAY -> 5
                Calendar.SATURDAY -> 6
                Calendar.SUNDAY -> 7
                else -> 1
            }

            val currentMinute = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)

            var isActive = false
            var activeBedtimeDay = mappedToday

            if (bedtime < wake) {
                // Same-day schedule (e.g. 14:00 to 18:00)
                if (weekdaysList.contains(mappedToday)) {
                    if (currentMinute in bedtime until wake) {
                        isActive = true
                    }
                }
            } else {
                // Overnight schedule wrapping midnight (e.g. 22:30 to 07:00)
                // Pre-midnight case
                if (currentMinute >= bedtime) {
                    if (weekdaysList.contains(mappedToday)) {
                        isActive = true
                    }
                }
                // Post-midnight case
                if (currentMinute < wake) {
                    val yesterday = if (mappedToday == 1) 7 else mappedToday - 1
                    if (weekdaysList.contains(yesterday)) {
                        isActive = true
                        activeBedtimeDay = yesterday
                    }
                }
            }

            if (isActive) {
                // Get start of bedtime day as baseline for sessionId
                val calendarBedtime = Calendar.getInstance().apply {
                    timeInMillis = now
                    if (activeBedtimeDay != mappedToday) {
                        add(Calendar.DAY_OF_YEAR, -1)
                    }
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val baseDayMillis = calendarBedtime.timeInMillis
                val activeUntilCal = Calendar.getInstance().apply {
                    timeInMillis = baseDayMillis
                    add(Calendar.DAY_OF_YEAR, if (bedtime < wake) 0 else 1)
                    set(Calendar.HOUR_OF_DAY, wake / 60)
                    set(Calendar.MINUTE, wake % 60)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }

                return JSONObject().apply {
                    put("sessionId", "sleep_${baseDayMillis}")
                    put("activeUntil", activeUntilCal.timeInMillis)
                    put("selectedPackages", selectedPackagesArr)
                    put("protectionMode", protectionLevel)
                    put("bypassAllowed", false)
                }
            }
        } catch (e: Exception) {
            // Fail-safe
        }
        return null
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
        source: String,
        bypassAllowed: Boolean
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
                put("bypassAllowed", bypassAllowed)
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
        // 1. FlowOS itself & Settings
        if (pkg == this.packageName || pkg == "com.android.settings") return true

        // 2. Telephony & Telecom (Dialer call UI and default Dialer)
        if (pkg.contains("telephony") || pkg == "com.android.phone" || pkg == "com.android.server.telecom") return true

        // 3. Default Dialer
        try {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            val defaultDialer = telecomManager?.defaultDialerPackage
            if (defaultDialer != null && pkg == defaultDialer) return true
        } catch (e: Exception) {}

        // 4. Default SMS package
        try {
            val defaultSms = android.provider.Telephony.Sms.getDefaultSmsPackage(this)
            if (defaultSms != null && pkg == defaultSms) return true
        } catch (e: Exception) {}

        // 5. Active call UI / Phone call state is not IDLE
        try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            if (telephonyManager != null && telephonyManager.callState != TelephonyManager.CALL_STATE_IDLE) {
                if (pkg.contains("dialer") || pkg.contains("contacts") || pkg.contains("phone")) return true
            }
        } catch (e: Exception) {}

        // 6. Resolved launchers
        try {
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            val resolveInfos = packageManager.queryIntentActivities(intent, 0)
            for (info in resolveInfos) {
                if (info.activityInfo.packageName == pkg) return true
            }
        } catch (e: Exception) {}

        // 7. Camera handlers (packages that handle MediaStore.ACTION_IMAGE_CAPTURE)
        try {
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            val resolveInfos = packageManager.queryIntentActivities(intent, 0)
            for (info in resolveInfos) {
                if (info.activityInfo.packageName == pkg) return true
            }
        } catch (e: Exception) {}

        // 8. Other hardcoded emergency/system packages
        val systemCritical = setOf(
            "com.android.emergency",
            "com.android.systemui"
        )
        if (systemCritical.contains(pkg)) return true

        return pkg.endsWith(".launcher")
    }

    override fun onInterrupt() {}
}
