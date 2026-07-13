package com.flowos.flowos

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray

class FocusBlockerService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        
        // Don't block ourselves
        if (packageName == this.packageName) return

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isFocusActive = prefs.getBoolean("flutter.is_focus_active", false)
        if (!isFocusActive) return

        val blockedUntil = prefs.getLong("flutter.blocked_until", 0L)
        if (System.currentTimeMillis() < blockedUntil) return

        val blockedPackagesJson = prefs.getString("flutter.blocked_packages", "[]") ?: "[]"
        val blockedPackages = parseJsonArray(blockedPackagesJson)

        if (blockedPackages.contains(packageName)) {
            // Redirect user back to FlowOS to show the shield page
            val launchIntent = packageManager.getLaunchIntentForPackage(this.packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("blocked_app_trigger", packageName)
            }
            if (launchIntent != null) {
                startActivity(launchIntent)
            }
        }
    }

    private fun parseJsonArray(jsonStr: String): Set<String> {
        return try {
            val set = mutableSetOf<String>()
            val array = JSONArray(jsonStr)
            for (i in 0 until array.length()) {
                set.add(array.getString(i))
            }
            set
        } catch (e: Exception) {
            emptySet()
        }
    }

    override fun onInterrupt() {}
}
