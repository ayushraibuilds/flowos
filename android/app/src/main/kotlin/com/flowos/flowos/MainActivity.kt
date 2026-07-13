package com.flowos.flowos

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val usageStatsChannel = "flowos/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                            result.success(todayUsageMinutes())
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
                            result.success(getUsageForDays(days))
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
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
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
        
        val calendar = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, -days + 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val statsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        ) ?: return emptyList()

        val aggregated = mutableMapOf<String, Long>()
        
        for (stats in statsList) {
            val foregroundTimeMs = stats.totalTimeInForeground
            if (foregroundTimeMs <= 0) continue

            val entryCal = Calendar.getInstance().apply {
                timeInMillis = stats.firstTimeStamp
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            
            val dateStr = String.format(
                "%04d-%02d-%02d",
                entryCal.get(Calendar.YEAR),
                entryCal.get(Calendar.MONTH) + 1,
                entryCal.get(Calendar.DAY_OF_MONTH)
            )

            val key = "${dateStr}_${stats.packageName}"
            aggregated[key] = (aggregated[key] ?: 0L) + foregroundTimeMs
        }

        val result = mutableListOf<Map<String, Any>>()
        for ((key, durationMs) in aggregated) {
            val minutes = durationMs / 60_000L
            if (minutes <= 0) continue

            val parts = key.split("_", limit = 2)
            if (parts.size == 2) {
                result.add(mapOf(
                    "date" to parts[0],
                    "packageName" to parts[1],
                    "label" to getAppName(parts[1]),
                    "minutes" to minutes
                ))
            }
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
}
