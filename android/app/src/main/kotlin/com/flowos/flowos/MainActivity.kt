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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar
import org.json.JSONObject
import org.json.JSONArray
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val usageStatsChannel = "flowos/usage_stats"
    private val deviceAttentionChannel = "flowos/device_attention"

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
                    "getLaunchableApps" -> {
                        result.success(getLaunchableAppsList())
                    }
                    "loadAppIcon" -> {
                        val pkg = call.argument<String>("packageName")
                        if (pkg != null) {
                            result.success(loadAppIcon(pkg))
                        } else {
                            result.error("bad_arguments", "Missing packageName", null)
                        }
                    }
                    "claimPendingBlockedAppTrigger" -> {
                        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                        val triggerStr = prefs.getString("flutter.flowos_pending_trigger", null)
                        if (triggerStr != null) {
                            try {
                                val trigger = JSONObject(triggerStr)
                                val id = trigger.optString("id")
                                val claimed = trigger.optBoolean("claimed", false)
                                val triggeredAt = trigger.optLong("triggeredAt", 0L)
                                val now = System.currentTimeMillis()

                                if (!claimed && (now - triggeredAt < 60000)) {
                                    trigger.put("claimed", true)
                                    prefs.edit().putString("flutter.flowos_pending_trigger", trigger.toString()).apply()

                                    result.success(mapOf(
                                        "id" to id,
                                        "packageName" to trigger.optString("packageName"),
                                        "triggeredAt" to triggeredAt,
                                        "source" to trigger.optString("source", "focus"),
                                        "claimed" to true,
                                        "bypassAllowed" to trigger.optBoolean("bypassAllowed", true)
                                    ))
                                    return@setMethodCallHandler
                                  }
                              } catch (e: Exception) {}
                          }
                          result.success(null)
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
                          result.success(getDefaultEssentialPackagesList())
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
                                  result.success(getDailyUsageRange(start, end))
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
                                  result.success(getDailyUnlockEventsRange(start, end))
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

    private fun isNotificationServiceEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat != null && flat.contains(packageName)
    }

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
        return apps.sortedBy { (it["label"] as? String)?.lowercase() }
    }

    private fun loadAppIcon(packageName: String): ByteArray? {
        return try {
            val pm = packageManager
            val icon = pm.getApplicationIcon(packageName)
            val bitmap = if (icon is BitmapDrawable) {
                icon.bitmap
            } else {
                val width = icon.intrinsicWidth.coerceAtLeast(1)
                val height = icon.intrinsicHeight.coerceAtLeast(1)
                val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                icon.setBounds(0, 0, canvas.width, canvas.height)
                icon.draw(canvas)
                bmp
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    private fun getDailyUsageRange(startMs: Long, endMs: Long): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val statsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startMs,
            endMs
        ) ?: return emptyList()

        val queriedDays = mutableSetOf<String>()
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
        while (startCal.before(endCal) || startCal.equals(endCal)) {
            val dateStr = String.format(
                "%04d-%02d-%02d",
                startCal.get(Calendar.YEAR),
                startCal.get(Calendar.MONTH) + 1,
                startCal.get(Calendar.DAY_OF_MONTH)
            )
            queriedDays.add(dateStr)
            startCal.add(Calendar.DATE, 1)
        }

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
        val datesWithUsage = mutableSetOf<String>()
        for ((key, durationMs) in aggregated) {
            val minutes = durationMs / 60_000L
            if (minutes <= 0) continue

            val parts = key.split("_", limit = 2)
            if (parts.size == 2) {
                val dateStr = parts[0]
                datesWithUsage.add(dateStr)
                result.add(mapOf(
                    "date" to dateStr,
                    "packageName" to parts[1],
                    "label" to getAppName(parts[1]),
                    "minutes" to minutes.toInt()
                ))
            }
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

        // Dialers
        val defaultDialer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? android.telecom.TelecomManager
            telecomManager?.defaultDialerPackage
        } else null
        if (defaultDialer != null) {
            list.add(mapOf("packageName" to defaultDialer, "reason" to "Phone/dialer"))
        }

        // SMS
        val defaultSms = android.provider.Telephony.Sms.getDefaultSmsPackage(this)
        if (defaultSms != null) {
            list.add(mapOf("packageName" to defaultSms, "reason" to "Default SMS"))
        }

        // Launchers
        val homeIntent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_HOME) }
        val homeInfos = pm.queryIntentActivities(homeIntent, 0)
        for (info in homeInfos) {
            val pkg = info.activityInfo.packageName
            list.add(mapOf("packageName" to pkg, "reason" to "Default Launcher"))
        }

        // Camera handlers (resolve ACTION_IMAGE_CAPTURE)
        val cameraIntent = Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE)
        val cameraInfos = pm.queryIntentActivities(cameraIntent, 0)
        val cameraPackages = cameraInfos.map { it.activityInfo.packageName }.toMutableSet()
        cameraPackages.add("com.android.camera")
        cameraPackages.add("com.android.camera2")
        cameraPackages.add("com.google.android.GoogleCamera")
        cameraPackages.add("com.sec.android.app.camera")

        for (pkg in cameraPackages) {
            list.add(mapOf("packageName" to pkg, "reason" to "Default Camera"))
        }

        // System packages & FlowOS itself
        list.add(mapOf("packageName" to packageName, "reason" to "FlowOS"))
        list.add(mapOf("packageName" to "com.android.settings", "reason" to "System settings"))
        list.add(mapOf("packageName" to "com.android.emergency", "reason" to "Emergency services"))
        list.add(mapOf("packageName" to "com.android.systemui", "reason" to "System UI"))

        return list
    }
}
