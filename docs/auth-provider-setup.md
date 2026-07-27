# Mobile Authentication & Provider Setup Guide

This document outlines the required configuration steps in the Supabase Dashboard, Apple Developer Console, and Google Cloud Console to enable deep link callbacks and OAuth sign-in for FlowOS.

---

## 1. Supabase Dashboard Configuration

1. Navigate to **Supabase Dashboard** -> **Authentication** -> **URL Configuration**.
2. Set **Site URL** to:
   `io.supabase.flowos://login-callback/`
3. Under **Redirect URLs** (Allow-list), add:
   - `io.supabase.flowos://login-callback/`
   - `io.supabase.flowos://login-callback/*`

---

## 2. Android Configuration (Google Sign-In)

1. Navigate to **Google Cloud Console** -> **APIs & Services** -> **Credentials**.
2. Ensure an **OAuth 2.0 Web Application Client ID** is configured for Supabase.
3. Ensure an **OAuth 2.0 Android Client ID** is configured with the app package name (`com.flowos.app`) and SHA-1 fingerprint.
4. Deep link intent filter registered in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <intent-filter>
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data
           android:scheme="io.supabase.flowos"
           android:host="login-callback" />
   </intent-filter>
   ```

---

## 3. iOS Configuration (Apple Sign-In)

1. Navigate to **Apple Developer Console** -> **Identifiers** -> App ID (`com.flowos.app`).
2. Enable **Sign In with Apple** capability.
3. Custom scheme registered in `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLName</key>
           <string>io.supabase.flowos</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>io.supabase.flowos</string>
           </array>
       </dict>
   </array>
   ```

---

## 4. Testing Callback Matrix

| Flow | Deep Link Callback URL | Expected Behavior |
| --- | --- | --- |
| Signup Email Confirmation | `io.supabase.flowos://login-callback/#access_token=...` | Opens app, refreshes session, redirects to `/home` |
| Password Reset | `io.supabase.flowos://login-callback/#access_token=...&type=recovery` | Opens app, refreshes session, prompts password update |
| OAuth Cancel / Deny | `io.supabase.flowos://login-callback/?error=access_denied` | Opens app, returns to `/auth` with cancellation feedback |
| Unrelated Deep Link | `other.scheme://malicious-host/` | Rejected by platform / router; no auth action taken |
