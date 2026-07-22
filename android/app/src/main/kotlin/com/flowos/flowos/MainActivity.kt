package com.flowos.flowos

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.provider.MediaStore
import android.telecom.TelecomManager
import android.util.LruCache
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar
import org.json.JSONObject
import org.json.JSONArray
import java.util.UUID
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private val usageStatsChannel = "flowos/usage_stats"
    private val deviceAttentionChannel = "flowos/device_attention"

    private val ioScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val iconCache = LruCache<String, ByteArray>(100)
    private val inFlightIconRequests = mutableMapOf<String, Deferred<ByteArray?>>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Keep flowos/usage_stats for backward compatibility during transition
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usageStatsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> result.success(hasUsageStatsPermission())
                    "requestPermission" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "getTodayUsage" -> {
                        if (!hasUsageStatsPermission()) {
                            result.error(
                                "permission_denied",
                                "Usage Access is required to read device screen time.",
                                null,
                            )
                        } else {
                            ioScope.launch {
                                val usage = todayUsageMinutes()
                                withContext(Dispatchers.Main) {
                                    result.success(usage)
                                }
                            }
                        }
                    }
                    "getUsageForDays" -> {
                        if (!hasUsageStatsPermission()) {
                            result.error(
                                "permission_denied",
                                "Usage Access is required to read device screen time.",
                                null,
                            )
                        } else {
                            val days = call.argument<Int>("days") ?: 1
                            ioScope.launch {
                                val usage = getUsageForDays(days)
                                withContext(Dispatchers.Main) {
                                    result.success(usage)
                                }
                            }
                        }
                    }
                    "checkUsagePermission" -> {
                        result.success(hasUsageStatsPermission())
                    }
                    "requestUsagePermission" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "checkAccessibilityPermission" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "requestAccessibilityPermission" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "getBlockedAppTrigger" -> {
                        val trigger = intent?.getStringExtra("blocked_app_trigger")
                        intent?.removeExtra("blocked_app_trigger")
                        result.success(trigger)
                    }
                    else -> result.notImplemented()
                }
            }

        // New consolidated flowos/device_attention channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceAttentionChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPermissionStates" -> {
                        result.success(mapOf(
                            "usageAccess" to hasUsageStatsPermission(),
                            "accessibility" to isAccessibilityServiceEnabled(),
                            "notificationAccess" to isNotificationServiceEnabled(),
                            "batteryOptimizationIgnored" to isIgnoringBatteryOptimizations(),
                            "platformSupport" to "android"
                        ))
                    }
                    "openUsageAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "openNotificationListenerSettings" -> {
                        startActivity(Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"))
                        result.success(null)
                    }
                    "openBatteryOptimizationSettings" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        result.success(isIgnoringBatteryOptimizations())
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(null)
                    }
                    "getLaunchableApps" -> {
                        ioScope.launch {
                            val apps = getLaunchableAppsList()
                            withContext(Dispatchers.Main) {
                                result.success(apps)
                            }
                        }
                    }
                    "loadAppIcon" -> {
                        val pkg = call.argument<String>("packageName")
                        if (pkg != null) {
                            ioScope.launch {
                                val iconBytes = getAppIconCached(pkg)
                                withContext(Dispatchers.Main) {
                                    result.success(iconBytes)
                                }
                            }
                        } else {
                            result.error("bad_arguments", "Missing packageName", null)
                        }
                    }
                    "claimPendingBlockedAppTrigger" -> {
                        val now = System.currentTimeMillis()
                        val claimed = TriggerStore.claimTrigger(this, now)
                        result.success(claimed)
                    }
                    "claimPendingNudge" -> {
                        val now = System.currentTimeMillis()
                        val claimed = NudgeStore.claim(this, now)
                        result.success(claimed)
                    }
                    "clearNudgesForSession" -> {
                        val sessionId = call.argument<String>("sessionId")
                        if (sessionId != null) {
                            NudgeStore.clearForSession(this, sessionId)
                        }
                        result.success(null)
                    }
                    "getDefaultEssentialPackages" -> {
                        ioScope.launch {
                            val list = getDefaultEssentialPackagesList()
                            withContext(Dispatchers.Main) {
                                result.success(list)
                            }
                        }
                    }
                    "getDailyUsage" -> {
                        val start = call.argument<Long>("startMs")
                        val end = call.argument<Long>("endMs")
                        if (start != null && end != null) {
                            if (!hasUsageStatsPermission()) {
                                result.error(
                                    "permission_denied",
                                    "Usage Access is required to read device screen time.",
                                    null,
                                )
                            } else {
                                ioScope.launch {
                                    val usage = getDailyUsageRange(start, end)
                                    withContext(Dispatchers.Main) {
                                        result.success(usage)
                                    }
                                }
                            }
                        } else {
                            result.error("bad_arguments", "Missing startMs or endMs", null)
                        }
                    }
                    "getDailyUnlockEvents" -> {
                        val start = call.argument<Long>("startMs")
                        val end = call.argument<Long>("endMs")
                        if (start != null && end != null) {
                            if (!hasUsageStatsPermission()) {
                                result.error(
                                    "permission_denied",
                                    "Usage Access is required to read unlock events.",
                                    null,
                                )
                            } else {
                                ioScope.launch {
                                    val unlocks = getDailyUnlockEventsRange(start, end)
                                    withContext(Dispatchers.Main) {
                                        result.success(unlocks)
                                    }
                                }
                            }
                        } else {
                            result.error("bad_arguments", "Missing startMs or endMs", null)
                        }
                    }
                    "startInFlightBatch" -> {
                        result.success(NotificationCountStore.startInFlightBatch(this))
                    }
                    "acknowledgeBatch" -> {
                        val batchId = call.argument<String>("batchId")
                        if (batchId != null) {
                            NotificationCountStore.acknowledgeBatch(this, batchId)
                            result.success(null)
                        } else {
                            result.error("bad_arguments", "Missing batchId", null)
                        }
                    }
                    "getUnacknowledgedBatches" -> {
                        result.success(NotificationCountStore.getUnacknowledgedBatches(this))
                    }
                    "wipeNotificationTracker" -> {
                        NotificationCountStore.wipeAll(this)
                        result.success(null)
                    }
                    "startForegroundService" -> {
                        FocusSessionForegroundService.start(this)
                        result.success(null)
                    }
                    "stopForegroundService" -> {
                        FocusSessionForegroundService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun onDestroy() {
        ioScope.cancel()
        super.onDestroy()
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            return powerManager.isIgnoringBatteryOptimizations(packageName)
        }
        return true
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = android.net.Uri.parse("package:$packageName")
                }
                startActivity(intent)
            } catch (e: Exception) {
                try {
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    startActivity(intent)
                } catch (_: Exception) {}
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun todayUsageMinutes(): Map<String, Long> {
        val usageStats = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val startOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val now = System.currentTimeMillis()

        return usageStats.queryAndAggregateUsageStats(startOfDay, now)
            .mapValues { (_, stats) -> stats.totalTimeInForeground / 60_000L }
            .filterValues { it > 0 }
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

    private fun getUsageForDays(days: Int): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val result = mutableListOf<Map<String, Any>>()
        
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        
        for (i in 0 until days) {
            val dayStart = calendar.timeInMillis
            val dayEndCal = (calendar.clone() as Calendar).apply {
                add(Calendar.DATE, 1)
            }
            val dayEnd = dayEndCal.timeInMillis
            
            val dateStr = String.format(
                "%04d-%02d-%02d",
                calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH) + 1,
                calendar.get(Calendar.DAY_OF_MONTH)
            )
            
            val statsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                dayStart,
                dayEnd
            )
            
            if (statsList != null) {
                val dailyAggregated = mutableMapOf<String, Long>()
                for (stats in statsList) {
                    val foregroundTimeMs = stats.totalTimeInForeground
                    if (foregroundTimeMs <= 0) continue
                    dailyAggregated[stats.packageName] = (dailyAggregated[stats.packageName] ?: 0L) + foregroundTimeMs
                }
                
                for ((pkg, durationMs) in dailyAggregated) {
                    val minutes = durationMs / 60_000L
                    if (minutes <= 0) continue
                    result.add(mapOf(
                        "date" to dateStr,
                        "packageName" to pkg,
                        "label" to getAppName(pkg),
                        "minutes" to minutes
                    ))
                }
            }
            calendar.add(Calendar.DATE, -1)
        }
        
        return result
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "$packageName/${FocusBlockerService::class.java.canonicalName}"
        val enabled = Settings.Secure.getInt(
            contentResolver,
            Settings.Secure.ACCESSIBILITY_ENABLED,
            0
        )
        if (enabled == 1) {
            val settingValue = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                val splitter = android.text.TextUtils.SimpleStringSplitter(':')
                splitter.setString(settingValue)
                while (splitter.hasNext()) {
                    val accessService = splitter.next()
                    if (accessService.equals(service, ignoreCase = true)) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat != null && flat.contains(packageName)
    }

    private val priorityPackages = setOf(
        "com.instagram.android",
        "com.google.android.youtube",
        "com.zhiliaoapp.musically",       // TikTok
        "com.twitter.android",
        "com.reddit.frontpage",
        "com.facebook.katana",
        "com.snapchat.android",
        "com.whatsapp",
        "com.discord",
        "com.android.chrome",
        "com.sec.android.app.sbrowser",   // Samsung Internet
        "org.mozilla.firefox",
        "com.brave.browser"
    )

    private fun getLaunchableAppsList(): List<Map<String, Any?>> {
        val pm = packageManager
        val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
        val apps = mutableListOf<Map<String, Any?>>()
        for (info in resolveInfos) {
            val pkgName = info.activityInfo.packageName
            if (pkgName == packageName) continue
            val label = info.loadLabel(pm).toString()
            apps.add(mapOf(
                "packageName" to pkgName,
                "label" to label
            ))
        }
        return apps.sortedWith(
            compareBy<Map<String, Any?>>(
                { if (priorityPackages.contains(it["packageName"])) 0 else 1 }
            ).thenBy { (it["label"] as? String)?.lowercase() }
        )
    }

    private fun loadAppIcon(packageName: String): ByteArray? {
        return try {
            val pm = packageManager
            val icon = pm.getApplicationIcon(packageName)
            
            val width = icon.intrinsicWidth.coerceAtLeast(1)
            val height = icon.intrinsicHeight.coerceAtLeast(1)
            
            // Limit maximum dimension to 144px to save space and transport bandwidth
            val maxDim = 144
            val (targetWidth, targetHeight) = if (width > maxDim || height > maxDim) {
                if (width > height) {
                    Pair(maxDim, (height * maxDim / width).coerceAtLeast(1))
                } else {
                    Pair((width * maxDim / height).coerceAtLeast(1), maxDim)
                }
            } else {
                Pair(width, height)
            }

            val bitmap = if (icon is BitmapDrawable && width <= maxDim && height <= maxDim) {
                icon.bitmap
            } else {
                val bmp = Bitmap.createBitmap(targetWidth, targetHeight, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                icon.setBounds(0, 0, targetWidth, targetHeight)
                icon.draw(canvas)
                bmp
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    private suspend fun getAppIconCached(packageName: String): ByteArray? = withContext(Dispatchers.IO) {
        val cached = iconCache.get(packageName)
        if (cached != null) return@withContext cached

        val deferred = synchronized(iconCache) {
            val existing = inFlightIconRequests[packageName]
            if (existing != null) {
                existing
            } else {
                val newDeferred = ioScope.async {
                    loadAppIcon(packageName)
                }
                inFlightIconRequests[packageName] = newDeferred
                newDeferred
            }
        }

        val result = deferred.await()
        synchronized(iconCache) {
            inFlightIconRequests.remove(packageName)
        }
        
        if (result != null) {
            iconCache.put(packageName, result)
        }
        return@withContext result
    }

    private fun getDailyUsageRange(startMs: Long, endMs: Long): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val result = mutableListOf<Map<String, Any>>()
        
        val startCal = Calendar.getInstance().apply {
            timeInMillis = startMs
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val endCal = Calendar.getInstance().apply {
            timeInMillis = endMs
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val queriedDays = mutableSetOf<String>()
        val datesWithUsage = mutableSetOf<String>()

        val activeCal = startCal.clone() as Calendar
        while (activeCal.before(endCal) || activeCal.equals(endCal)) {
            val dateStr = String.format(
                "%04d-%02d-%02d",
                activeCal.get(Calendar.YEAR),
                activeCal.get(Calendar.MONTH) + 1,
                activeCal.get(Calendar.DAY_OF_MONTH)
            )
            queriedDays.add(dateStr)

            val dayStart = activeCal.timeInMillis
            val dayEndCal = (activeCal.clone() as Calendar).apply {
                add(Calendar.DATE, 1)
            }
            val dayEnd = dayEndCal.timeInMillis

            val statsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                dayStart,
                dayEnd
            )

            if (statsList != null) {
                val dailyAggregated = mutableMapOf<String, Long>()
                for (stats in statsList) {
                    val foregroundTimeMs = stats.totalTimeInForeground
                    if (foregroundTimeMs <= 0) continue
                    dailyAggregated[stats.packageName] = (dailyAggregated[stats.packageName] ?: 0L) + foregroundTimeMs
                }

                for ((pkg, durationMs) in dailyAggregated) {
                    val minutes = durationMs / 60_000L
                    if (minutes <= 0) continue
                    datesWithUsage.add(dateStr)
                    result.add(mapOf(
                        "date" to dateStr,
                        "packageName" to pkg,
                        "label" to getAppName(pkg),
                        "minutes" to minutes.toInt()
                    ))
                }
            }
            activeCal.add(Calendar.DATE, 1)
        }

        for (dateStr in queriedDays) {
            if (!datesWithUsage.contains(dateStr)) {
                result.add(mapOf(
                    "date" to dateStr,
                    "packageName" to "",
                    "label" to "",
                    "minutes" to 0
                ))
            }
        }

        return result
    }

    private fun getDailyUnlockEventsRange(startMs: Long, endMs: Long): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usageStatsManager.queryEvents(startMs, endMs) ?: return emptyList()
        
        val dailyUnlocks = mutableMapOf<String, MutableSet<Long>>()
        val event = UsageEvents.Event()
        
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val isKeyguardHidden = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                event.eventType == UsageEvents.Event.KEYGUARD_HIDDEN
            } else {
                event.eventType == 18
            }
            
            if (isKeyguardHidden) {
                val timestamp = event.timeStamp
                val cal = Calendar.getInstance().apply {
                    timeInMillis = timestamp
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                val dateStr = String.format(
                    "%04d-%02d-%02d",
                    cal.get(Calendar.YEAR),
                    cal.get(Calendar.MONTH) + 1,
                    cal.get(Calendar.DAY_OF_MONTH)
                )
                
                if (!dailyUnlocks.containsKey(dateStr)) {
                    dailyUnlocks[dateStr] = mutableSetOf()
                }
                val isDuplicate = dailyUnlocks[dateStr]?.any { Math.abs(it - timestamp) < 2000L } ?: false
                if (!isDuplicate) {
                    dailyUnlocks[dateStr]?.add(timestamp)
                }
            }
        }
        
        val result = mutableListOf<Map<String, Any>>()
        for ((dateStr, timestamps) in dailyUnlocks) {
            result.add(mapOf(
                "date" to dateStr,
                "count" to timestamps.size
            ))
        }
        return result
    }

    private fun getDefaultEssentialPackagesList(): List<Map<String, String>> {
        val pm = packageManager
        val list = mutableListOf<Map<String, String>>()

        val defaultDialer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            telecomManager?.defaultDialerPackage
        } else null
        if (defaultDialer != null) {
            list.add(mapOf("packageName" to defaultDialer, "reason" to "Phone/dialer"))
        }

        val defaultSms = android.provider.Telephony.Sms.getDefaultSmsPackage(this)
        if (defaultSms != null) {
            list.add(mapOf("packageName" to defaultSms, "reason" to "Default SMS"))
        }

        val homeIntent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_HOME) }
        val homeInfos = pm.queryIntentActivities(homeIntent, 0)
        for (info in homeInfos) {
            val pkg = info.activityInfo.packageName
            list.add(mapOf("packageName" to pkg, "reason" to "Default Launcher"))
        }

        val cameraIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        val cameraInfos = pm.queryIntentActivities(cameraIntent, 0)
        val cameraPackages = cameraInfos.map { it.activityInfo.packageName }.toMutableSet()
        cameraPackages.add("com.android.camera")
        cameraPackages.add("com.android.camera2")
        cameraPackages.add("com.google.android.GoogleCamera")
        cameraPackages.add("com.sec.android.app.camera")

        for (pkg in cameraPackages) {
            list.add(mapOf("packageName" to pkg, "reason" to "Default Camera"))
        }

        list.add(mapOf("packageName" to packageName, "reason" to "FlowOS"))
        list.add(mapOf("packageName" to "com.android.settings", "reason" to "System settings"))
        list.add(mapOf("packageName" to "com.android.emergency", "reason" to "Emergency services"))
        list.add(mapOf("packageName" to "com.android.systemui", "reason" to "System UI"))

        return list
    }
}
