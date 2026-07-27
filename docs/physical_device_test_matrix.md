# FlowOS Physical Device & OEM Manual Verification Matrix

This matrix documents manual verification procedures for hardware, platform, and OEM-specific behaviors that cannot be fully automated in headless CI environments.

---

## 1. OEM Battery Optimization & Background Execution Matrix

| OEM / System | Test Device | Setup Steps | Verification Procedure | Expected Result | Evidence Required |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Google Pixel (Stock Android 13+)** | Pixel 7 (Android 14) | Install release APK. Enable Focus Protection. | Start a 25-min focus session. Turn off screen for 15 mins. | Foreground service notification remains active. App shielding triggers immediately on launch of blocked app. | Logcat output showing active `DeviceAttentionService` and notification channel status. |
| **Samsung OneUI (Android 13/14)** | Galaxy S23 (OneUI 6) | Settings -> Apps -> FlowOS -> Battery -> Unrestricted. Enable Autostart. | Start Focus Protection. Allow phone to enter Deep Sleep mode. Attempt to open a restricted app. | Protection mode remains enforced despite Samsung App Power Saving. | Screenshot of app shield overlay and battery setting confirmation. |
| **Xiaomi / Poco (HyperOS / MIUI 14)** | Poco F5 (HyperOS 1.0) | App Info -> Autostart -> ON. Battery saver -> No restrictions. | Start Focus Protection. Background FlowOS. Trigger notification alarm. | Foreground service and notification alarms trigger reliably. | Logcat snippet showing service launch without MIUI autostart kill. |

---

## 2. Platform Permission & System Services Matrix

| Feature | Target API | User Journey | Verification Procedure | Expected Result | Pass/Fail Criteria |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Accessibility Service App-Blocking** | Android 8.0+ (API 26+) | Device Setup -> Enable App Blocker | Tap "Grant Access". Redirect to Accessibility Settings. Enable FlowOS Service. Return to app. | Permission status updates to "Granted" in app UI. Blocked app launches immediately redirect to FlowOS overlay. | Pass: Redirect occurs within 500ms of launching blocked app. Fail: Blocked app opens without overlay. |
| **Usage Stats Special Permission** | Android 5.0+ (API 21+) | Onboarding / Settings -> App Usage Permission | Tap "Grant Usage Stats". Redirect to Usage Access screen. Toggle FlowOS -> Allowed. Return. | `UsageStatsService` successfully reads daily app usage minutes. Native distracting scroll minutes populate on Flow Garden. | Pass: Scroll logs show native distracting minutes. Fail: Returns 0 minutes without error fallback. |
| **Android 13+ Notification Permission** | Android 13+ (API 33+) | First App Launch | Launch app. Prompt `POST_NOTIFICATIONS` runtime dialog. Tap "Allow". | Scheduled energy check-in and streak warnings render in system tray at target local times. | Pass: System notification appears at scheduled local time. Fail: Notification suppressed by system. |
| **Hardware Back Button Interception** | Android All Versions | Active Focus Protection Session | Launch a blocked app -> FlowOS Shield overlay appears. Press physical/gesture Back button. | Back button is intercepted; user cannot bypass shield to access restricted app. | Pass: Back button closes overlay back to Home screen, not into blocked app. |

---

## 3. Physical Device Verification Sign-Off Form

- **Tester Name**: __________________________
- **Device Model & Build**: __________________________
- **Android Version**: __________________________
- **Test Date**: __________________________
- **Result**: `[ ] PASS`  `[ ] FAIL`
- **Notes / Observations**:
