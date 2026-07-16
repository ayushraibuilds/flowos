package com.flowos.flowos

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.provider.MediaStore
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

class FocusBlockerService : AccessibilityService() {

    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    private val appLabelsMap = ConcurrentHashMap<String, String>()

    @Volatile
    private var cachedEssentialPackages = emptySet<String>()

    @Volatile
    private var currentPolicy: PolicySnapshot? = null

    @Volatile
    private var currentSleepConfig: SleepConfigSnapshot? = null

    private val preferenceListener = SharedPreferences.OnSharedPreferenceChangeListener { sharedPreferences, key ->
        if (key == "flutter.flowos_active_policies" || key == "flutter.flowos_sleep_config") {
            backgroundExecutor.execute {
                reloadPolicies(sharedPreferences)
            }
        }
    }

    private val packageUpdateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            backgroundExecutor.execute {
                reloadEssentialPackages()
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()

        // Register package event listeners
        try {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_PACKAGE_ADDED)
                addAction(Intent.ACTION_PACKAGE_REMOVED)
                addAction(Intent.ACTION_PACKAGE_CHANGED)
                addDataScheme("package")
            }
            registerReceiver(packageUpdateReceiver, filter)

            val appChangeFilter = IntentFilter().apply {
                addAction("android.telecom.action.DEFAULT_DIALER_CHANGED")
                addAction("android.provider.Telephony.ACTION_DEFAULT_SMS_PACKAGE_CHANGED")
            }
            registerReceiver(packageUpdateReceiver, appChangeFilter)
        } catch (e: Exception) {}

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.registerOnSharedPreferenceChangeListener(preferenceListener)

        backgroundExecutor.execute {
            reloadEssentialPackages()
            reloadPolicies(prefs)
        }
    }

    override fun onDestroy() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.unregisterOnSharedPreferenceChangeListener(preferenceListener)
        try {
            unregisterReceiver(packageUpdateReceiver)
        } catch (e: Exception) {}
        backgroundExecutor.shutdown()
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // 1. Cached essential check (hot path bypass)
        if (cachedEssentialPackages.contains(packageName)) return
        if (isCallActiveAndPkgEssential(packageName)) return

        val now = System.currentTimeMillis()

        // 2. Evaluate Focus Blocker Policy from memory snapshot
        val policy = currentPolicy
        var focusMode: String? = null
        var focusSessionId: String? = null
        var isFocusActive = false

        if (policy != null && now <= policy.focusActiveUntil) {
            if (policy.focusPackages.contains(packageName)) {
                focusMode = policy.focusMode
                focusSessionId = policy.focusSessionId
                isFocusActive = true
            }
        }

        // 3. Evaluate Dynamic Sleep Policy from memory config snapshot
        val sleepConfig = currentSleepConfig
        val sleepEvaluation = if (sleepConfig != null) evaluateDynamicSleepPolicy(sleepConfig, packageName, now) else null
        var sleepMode: String? = null
        var sleepSessionId: String? = null
        var isSleepActive = false

        if (sleepEvaluation != null && now <= sleepEvaluation.activeUntil) {
            sleepMode = sleepEvaluation.protectionMode
            sleepSessionId = sleepEvaluation.sessionId
            isSleepActive = true
        }

        // If neither is protecting this package, we're done
        if (!isFocusActive && !isSleepActive) return

        // Resolve effective mode by stricter-wins (deep = 2, guard = 1, nudge = 0)
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
        if (activeSource == "focus" && policy != null) {
            val breakExpiresAt = policy.focusBreaks[packageName]
            if (breakExpiresAt != null && now <= breakExpiresAt) {
                // Focus scoped break is active.
                // But wait: if sleep is also active, is it stricter?
                if (isSleepActive && sleepVal > focusVal) {
                    // Sleep overrides focus break because it's stricter
                } else {
                    return // App allowed through (Focus break active and Sleep is not stricter)
                }
            }
        }

        // Apply protection behavior
        if (effectiveMode == "nudge") {
            val appLabel = getAppNameCached(packageName)
            NudgeStore.record(this, packageName, appLabel, now, activeSessionId, activeSource)
        } else {
            // Guard or Deep: Intercept and redirect to FlowOS shield page
            // For Focus Guard, bypass (timed breaks) is allowed. Sleep Guard does NOT.
            val bypassAllowed = if (activeSource == "focus") (effectiveMode == "guard") else false
            
            // Atomic check, debounce and write trigger
            val didTrigger = TriggerStore.writeTrigger(this, packageName, now, activeSource, bypassAllowed)
            if (didTrigger) {
                redirectUser(packageName)
            }
        }
    }

    private fun reloadPolicies(prefs: SharedPreferences) {
        val activePoliciesJson = prefs.getString("flutter.flowos_active_policies", null)
        currentPolicy = PolicySnapshot.fromJson(activePoliciesJson)

        val sleepConfigJson = prefs.getString("flutter.flowos_sleep_config", null)
        currentSleepConfig = SleepConfigSnapshot.fromJson(sleepConfigJson)
    }

    private fun reloadEssentialPackages() {
        val essentials = mutableSetOf<String>()
        
        // Always safeguard FlowOS itself & Android settings
        essentials.add(packageName)
        essentials.add("com.android.settings")
        essentials.add("com.android.emergency")
        essentials.add("com.android.systemui")

        val pm = packageManager
        
        // Default Dialer
        try {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            val defaultDialer = telecomManager?.defaultDialerPackage
            if (defaultDialer != null) {
                essentials.add(defaultDialer)
            }
        } catch (e: Exception) {}

        // Default SMS
        try {
            val defaultSms = android.provider.Telephony.Sms.getDefaultSmsPackage(this)
            if (defaultSms != null) {
                essentials.add(defaultSms)
            }
        } catch (e: Exception) {}

        // System Launchers
        try {
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            val resolveInfos = pm.queryIntentActivities(intent, 0)
            for (info in resolveInfos) {
                essentials.add(info.activityInfo.packageName)
            }
        } catch (e: Exception) {}

        // System Camera apps
        try {
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            val resolveInfos = pm.queryIntentActivities(intent, 0)
            for (info in resolveInfos) {
                essentials.add(info.activityInfo.packageName)
            }
        } catch (e: Exception) {}

        cachedEssentialPackages = essentials
    }

    private fun isCallActiveAndPkgEssential(pkg: String): Boolean {
        if (pkg.contains("dialer") || pkg.contains("contacts") || pkg.contains("phone")) {
            try {
                val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
                if (telephonyManager != null && telephonyManager.callState != TelephonyManager.CALL_STATE_IDLE) {
                    return true
                }
            } catch (e: Exception) {}
        }
        return false
    }

    private fun evaluateDynamicSleepPolicy(config: SleepConfigSnapshot, packageName: String, now: Long): SleepPolicyEvaluation? {
        if (!config.enabled) return null
        if (!config.selectedPackages.contains(packageName)) return null

        val bedtime = config.bedtimeMinute
        val wake = config.wakeMinute

        val calendar = Calendar.getInstance().apply { timeInMillis = now }
        val currentDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
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
            if (config.weekdays.contains(mappedToday)) {
                if (currentMinute in bedtime until wake) {
                    isActive = true
                }
            }
        } else {
            if (currentMinute >= bedtime) {
                if (config.weekdays.contains(mappedToday)) {
                    isActive = true
                }
            }
            if (currentMinute < wake) {
                val yesterday = if (mappedToday == 1) 7 else mappedToday - 1
                if (config.weekdays.contains(yesterday)) {
                    isActive = true
                    activeBedtimeDay = yesterday
                }
            }
        }

        if (isActive) {
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

            return SleepPolicyEvaluation(
                sessionId = "sleep_${baseDayMillis}",
                activeUntil = activeUntilCal.timeInMillis,
                protectionMode = config.protectionLevel,
                bypassAllowed = false
            )
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

    private fun getAppNameCached(packageName: String): String {
        val cached = appLabelsMap[packageName]
        if (cached != null) return cached

        backgroundExecutor.execute {
            try {
                val pm = packageManager
                val info = pm.getApplicationInfo(packageName, 0)
                val label = info.loadLabel(pm).toString()
                appLabelsMap[packageName] = label
            } catch (e: Exception) {
                appLabelsMap[packageName] = packageName
            }
        }
        return packageName
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

    override fun onInterrupt() {}
}

// ─── Data Models ──────────────────────────────────────────────────

class PolicySnapshot(
    val schemaVersion: Int,
    val focusSessionId: String?,
    val focusActiveUntil: Long,
    val focusPackages: Set<String>,
    val focusMode: String?,
    val focusBypassAllowed: Boolean,
    val focusBreaks: Map<String, Long>
) {
    companion object {
        fun fromJson(jsonStr: String?): PolicySnapshot? {
            if (jsonStr.isNullOrEmpty()) return null
            try {
                val json = JSONObject(jsonStr)
                val schemaVersion = json.optInt("schemaVersion", -1)
                if (schemaVersion != 1) return null

                val focusJson = json.optJSONObject("focus") ?: return null
                val sessionId = focusJson.optString("sessionId", "")
                val activeUntil = focusJson.optLong("activeUntil", 0L)
                val selectedPackagesArr = focusJson.optJSONArray("selectedPackages")
                val protectionMode = focusJson.optString("protectionMode", "")
                val source = focusJson.optString("source", "")

                if (sessionId.isEmpty() || activeUntil <= 0 || selectedPackagesArr == null || protectionMode.isEmpty() || source != "focus") {
                    return null
                }
                if (protectionMode != "nudge" && protectionMode != "guard" && protectionMode != "deep") {
                    return null
                }

                val selectedPackages = mutableSetOf<String>()
                for (i in 0 until selectedPackagesArr.length()) {
                    selectedPackages.add(selectedPackagesArr.optString(i))
                }

                val breaksMap = mutableMapOf<String, Long>()
                val breaksArr = focusJson.optJSONArray("scopedBreaks")
                if (breaksArr != null) {
                    for (i in 0 until breaksArr.length()) {
                        val b = breaksArr.optJSONObject(i) ?: continue
                        val pkg = b.optString("packageName", "")
                        val expires = b.optLong("expiresAt", 0L)
                        if (pkg.isNotEmpty() && expires > 0) {
                            breaksMap[pkg] = expires
                        }
                    }
                }

                val bypassAllowed = (protectionMode == "guard")

                return PolicySnapshot(
                    schemaVersion = schemaVersion,
                    focusSessionId = sessionId,
                    focusActiveUntil = activeUntil,
                    focusPackages = selectedPackages,
                    focusMode = protectionMode,
                    focusBypassAllowed = bypassAllowed,
                    focusBreaks = breaksMap
                )
            } catch (e: Exception) {
                return null
            }
        }
    }
}

class SleepConfigSnapshot(
    val schemaVersion: Int,
    val enabled: Boolean,
    val bedtimeMinute: Int,
    val wakeMinute: Int,
    val weekdays: Set<Int>,
    val selectedPackages: Set<String>,
    val protectionLevel: String
) {
    companion object {
        fun fromJson(jsonStr: String?): SleepConfigSnapshot? {
            if (jsonStr.isNullOrEmpty()) return null
            try {
                val json = JSONObject(jsonStr)
                val schemaVersion = json.optInt("schemaVersion", -1)
                if (schemaVersion != 1) return null

                val enabled = json.optBoolean("enabled", false)
                val bedtime = json.optInt("bedtimeMinute", -1)
                val wake = json.optInt("wakeMinute", -1)
                if (bedtime == -1 || wake == -1 || bedtime == wake) return null

                val weekdaysArr = json.optJSONArray("weekdays") ?: return null
                val weekdays = mutableSetOf<Int>()
                for (i in 0 until weekdaysArr.length()) {
                    weekdays.add(weekdaysArr.optInt(i))
                }

                val selectedPackagesArr = json.optJSONArray("selectedPackages") ?: return null
                val selectedPackages = mutableSetOf<String>()
                for (i in 0 until selectedPackagesArr.length()) {
                    selectedPackages.add(selectedPackagesArr.optString(i))
                }

                val protectionLevel = json.optString("protectionLevel", "guard")
                if (protectionLevel != "nudge" && protectionLevel != "guard" && protectionLevel != "deep") {
                    return null
                }

                return SleepConfigSnapshot(
                    schemaVersion = schemaVersion,
                    enabled = enabled,
                    bedtimeMinute = bedtime,
                    wakeMinute = wake,
                    weekdays = weekdays,
                    selectedPackages = selectedPackages,
                    protectionLevel = protectionLevel
                )
            } catch (e: Exception) {
                return null
            }
        }
    }
}

class SleepPolicyEvaluation(
    val sessionId: String,
    val activeUntil: Long,
    val protectionMode: String,
    val bypassAllowed: Boolean
)
