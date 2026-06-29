# FlowOS — Offline vs Online Analysis & Pre-Testing Readiness Report

> **Generated:** 2026-06-29 • **Version:** 0.1.0 • **Status:** Pre-Testing Audit

---

## Table of Contents

1. [Offline vs Online Feature Matrix](#1-offline-vs-online-feature-matrix)
2. [Detailed Feature Breakdown](#2-detailed-feature-breakdown)
3. [Ambient Sound Architecture — How Music Works](#3-ambient-sound-architecture--how-music-works)
4. [Planned Future Features](#4-planned-future-features)
5. [Cost Analysis & Free/Cheap Alternatives](#5-cost-analysis--freecheap-alternatives)
6. [Pre-Testing Readiness Audit (Offline)](#6-pre-testing-readiness-audit-offline)
7. [Blockers & Fixes Required Before Testing](#7-blockers--fixes-required-before-testing)
8. [Recommendations Summary](#8-recommendations-summary)

---

## 1. Offline vs Online Feature Matrix

### Quick Overview

| Feature | Offline | Online | Notes |
|---------|:-------:|:------:|-------|
| **Task Management** | ✅ Full | ✅ Synced | CRUD, MITs, energy levels, friction scores — all in local SQLite |
| **Morning Intention** | ✅ Full | ✅ Synced | Set MITs, scroll budget, day plan — stored locally via Drift |
| **Focus Timer (Pomodoro)** | ✅ Full | ✅ Synced | 25-min timer, session logging, XP — fully local |
| **Deep Work Timer (90 min)** | ✅ Full | ✅ Synced | 90-min countdown, pause tracking, quality grading — fully local |
| **Focus Ritual** | ✅ Full | — | Pre-focus checklist + breathing — local only, earns XP |
| **Shutdown Ritual** | ✅ Full | ✅ Synced | End-of-day checklist, marks plan as complete — local with sync |
| **XP System** | ✅ Full | ✅ Synced | All XP calculations, levels, tiers — computed locally |
| **Daily Score** | ✅ Full | — | 0-100 score + grade (A+ to F) — pure local math |
| **Scroll Tracker** | ✅ Full | ✅ Synced | Manual time logging, budget tracking, recovery actions — local |
| **Energy Check-ins** | ✅ Full | ✅ Synced | 1-5 energy logging — stored locally |
| **Achievements / Badges** | ✅ Full | ✅ Synced | 13 badge conditions checked against local DB |
| **Streak Counter** | ✅ Full | ✅ Synced | Calculated from local DailyPlans history |
| **Profile / Stats** | ✅ Full | — | Level, tier name, lifetime XP — all from local ledger |
| **Themes (Dark/Unlockable)** | ✅ Full | — | Level-gated theme list, dark mode default — local |
| **Notifications** | ✅ Full | — | flutter_local_notifications — 100% on-device |
| **Home Widgets** | ✅ Full | — | iOS WidgetKit / Android Glance — reads local data |
| **Settings** | ✅ Full | — | Scroll budget, notification prefs — local SharedPreferences |
| **Onboarding** | ✅ Full | — | 3-screen flow — no network needed |
| **Ambient Sounds** | ⚠️ **Blocked** | — | Requires bundled MP3 files (currently missing — see §3) |
| **Brain Dump → AI Tasks** | ❌ None | ✅ Required | Text → AI-sorted tasks. **No offline fallback.** |
| **Daily Report AI Insight** | ⚠️ Fallback | ✅ Enhanced | Uses `DailyReportInsight.fallback()` when AI unreachable |
| **Weekly Review AI** | ⚠️ Fallback | ✅ Enhanced | Falls back to hardcoded reflection questions |
| **Break Content (AI)** | ⚠️ Static | ✅ Enhanced | Shows static riddles/facts. AI provides dynamic content |
| **Authentication** | ⚠️ Skip | ✅ Required | "Use offline (no sync)" button bypasses login |
| **Cloud Sync** | ❌ N/A | ✅ Required | Bidirectional Drift ↔ Supabase. Guarded by `SupabaseConfig.isConfigured` |
| **Multi-Device Data** | ❌ N/A | ✅ Required | Needs Supabase for cross-device access |
| **Google Fonts (Inter)** | ⚠️ Cached | ✅ Required | First load needs network. Caches afterwards. See §7 |

### Legend
- ✅ **Full** — Feature works completely in this mode
- ⚠️ **Partial/Blocked** — Works with limitations or has a prerequisite
- ❌ **None/N/A** — Feature is unavailable in this mode

---

## 2. Detailed Feature Breakdown

### 2A. Fully Offline Features (No Network Needed)

These features are **100% functional** without any internet connection, powered by Drift (SQLite):

#### Core Productivity Loop
| Feature | How It Works Offline | Data Storage |
|---------|---------------------|--------------|
| **Task CRUD** | Create, edit, delete, reorder tasks | `Tasks` table in Drift |
| **MITs (Most Important Tasks)** | Mark up to 3 tasks as MITs each morning | `isMIT` flag in `Tasks` table |
| **Morning Intention** | Set daily MITs + scroll budget | `DailyPlans` table (upserted per day) |
| **Focus Timer** | 25-min Pomodoro, session quality grading | `FocusSessions` table |
| **Deep Work Timer** | 90-min session, pause count, quality grade | `FocusSessions` table (type: `deepWork`) |
| **Focus Ritual** | Pre-session checklist + 4-7-8 breathing | XP logged to `XpLedgerEntries` |
| **Shutdown Ritual** | End-of-day checklist, marks day complete | Updates `DailyPlans.shutdownCompleted` |
| **Break Screen** | XP reveal animation + static break content | Receives data via route `extras` |

#### Tracking & Analytics
| Feature | How It Works Offline | Data Storage |
|---------|---------------------|--------------|
| **Scroll Tracker** | Manual timer + quick-log slider | `ScrollLogs` table |
| **Energy Check-ins** | 1-5 energy scale with timestamps | `EnergyCheckIns` table |
| **Daily Score** | Weighted formula: focus + MITs + scroll budget + rituals | Computed at read time from DAOs |
| **Streak Counter** | Counts consecutive days with `intentionCompleted = true` | Derived from `DailyPlans` history |
| **Attention Budget** | Visual progress bar against configurable budget | `ScrollLogs` vs `DailyPlans.scrollBudgetMinutes` |

#### Gamification
| Feature | How It Works Offline | Data Storage |
|---------|---------------------|--------------|
| **XP System** | Earn XP for tasks, focus, rituals, recovery actions | `XpLedgerEntries` (append-only) |
| **Level / Tier** | Quadratic scaling: Level = √(totalXP / 100) | Computed from `SUM(points_delta)` |
| **Achievements** | 13 badges with DB-query-based conditions | `Achievements` table |
| **Unlockable Themes** | Level-gated custom color themes | Local state + level check |

#### UI & System
| Feature | How It Works Offline | Data Storage |
|---------|---------------------|--------------|
| **Dark Theme** | Primary theme, Material 3, glassmorphic cards | `AppTheme.dark` |
| **Local Notifications** | Focus reminders, energy check-in prompts, streak warnings | `flutter_local_notifications` |
| **Home Widgets** | iOS WidgetKit / Android Glance — show score/MITs/streak | `home_widget` package reads saved data |
| **Share Daily Report** | Screenshot + share via `share_plus` | Renders report widget to image |
| **Bottom Nav** | 4-tab shell: Home, Tasks, Focus, Profile | GoRouter shell route |
| **Settings** | Theme selection, notification prefs, scroll budget | Local state + SharedPreferences |

---

### 2B. Online-Only Features (Require Network)

| Feature | Dependency | What Happens Offline |
|---------|-----------|---------------------|
| **Brain Dump AI** | FastAPI backend → Gemini API | **Screen opens but AI call fails** — returns `null`, shows empty state. **No local fallback for task classification.** |
| **Cloud Sync** | Supabase (PostgreSQL) | Guarded by `SupabaseConfig.isConfigured`. If not configured, sync code never runs. No errors. |
| **Authentication** | Supabase Auth | Auth screen shows — user taps **"Use offline (no sync)"** to skip directly to `/home` |
| **Multi-Device** | Supabase | Data stays on-device until sync is configured |

### 2C. Features with Graceful Degradation

These features **work offline** but are **enhanced** when online:

| Feature | Offline Behavior | Online Enhancement |
|---------|-----------------|-------------------|
| **Daily Report** | All stats (score, XP, focus min, tasks) calculated locally. AI insight shows **fallback text**: *"You showed up today. That matters more than any score."* | AI generates **personalized** headline, highlight, growth area, energy insight, and tomorrow tip |
| **Weekly Review** | Shows **hardcoded** reflection questions and generic summary | AI generates **personalized** weekly summary, wins, growth areas, and reflection prompts |
| **Break Content** | Shows **static** riddle/fact/breathing from local list | AI generates **dynamic** content based on session data |
| **Google Fonts (Inter)** | After first successful load, fonts are cached to disk. Falls back to system sans-serif on first use without network | Fetches and caches Inter font family from Google's CDN |

---

## 3. Ambient Sound Architecture — How Music Works

### Current Design: Bundled MP3 Assets

The ambient sound system is designed to use **pre-loaded MP3 files bundled inside the app binary** — no streaming or online fetching.

```
assets/sounds/
├── binaural_40hz.mp3     ← 40Hz gamma binaural beats
├── rain_loop.mp3         ← Rain ambiance loop  
├── cafe_ambiance.mp3     ← Café chatter ambiance
└── forest_loop.mp3       ← Forest/nature sounds
```

#### How It Works

1. **`AmbientSoundPlayer`** (in `lib/features/focus/services/ambient_sound_player.dart`) uses the `just_audio` package
2. Files are loaded via `_player.setAsset('assets/sounds/rain_loop.mp3')` — this reads from the Flutter asset bundle compiled into the APK/IPA
3. Each sound loops seamlessly using `LoopMode.one` (gapless)
4. Default volume is `0.4` (subtle background)
5. On session end, the player does a **3-second fade-out** (15 steps of linear volume reduction) before stopping
6. The Deep Work Screen shows 4 sound buttons (🌊 Rain, ☕ Café, 🌲 Forest, 🧠 Binaural) — user taps to switch

#### Why Bundled MP3s (Not Streaming)

| Criterion | Bundled (Current) | Streaming |
|-----------|:-----------------:|:---------:|
| Works offline | ✅ Yes | ❌ No |
| Latency | ✅ Instant | ⚠️ Buffering |
| Data usage | ✅ Zero | ❌ Uses data |
| Gapless looping | ✅ Perfect | ⚠️ May stutter |
| App size impact | ⚠️ +8–15 MB | ✅ None |
| Variety | ⚠️ Fixed 4 sounds | ✅ Unlimited |

#### 🚨 CURRENT BLOCKER: MP3 Files Are Missing

> The `assets/sounds/` directory currently contains only a `.gitkeep` placeholder file. **No actual audio files exist.** The ambient sound feature will crash with a `just_audio` asset-not-found error when a user taps any sound button during a Deep Work session.

**Resolution — see [§7 Blockers](#7-blockers--fixes-required-before-testing).**

#### Future Enhancement: Hybrid Approach (Planned)

A hybrid approach could offer the best of both worlds:
1. **4 bundled sounds** ship with the app (always available offline)
2. **Additional sound packs** downloadable from a CDN (Firebase Storage or Supabase Storage)
3. Downloaded packs cached to the app's documents directory
4. UI shows a lock icon on downloadable packs with a download button

This would keep the app size reasonable while allowing expansion.

---

## 4. Planned Future Features

### Phase 1 — Immediate (v0.2)

| Feature | Description | Offline/Online |
|---------|-------------|:--------------:|
| **Light Theme** | Custom light mode color scheme and styling. Currently `AppTheme.light` returns `dark` as placeholder | Offline |
| **Adaptive Tablet Layout** | Side-by-side master-detail views on tablets, `NavigationRail` instead of bottom nav bar | Offline |
| **Flow Garden** | Visual garden that grows with productivity — trees/flowers represent focus sessions. Directory structure exists (`features/flow_garden/`) but models are empty `.gitkeep` | Offline |

### Phase 2 — Backend Integration (v0.3)

| Feature | Description | Offline/Online |
|---------|-------------|:--------------:|
| **AI Backend Deployment** | Deploy FastAPI to Railway/Render, connect Supabase cloud, apply migrations | Online |
| **Brain Dump Offline Fallback** | Simple local rules-based task splitter when AI is unreachable (split by line, assign energy levels by keyword) | Offline |
| **Real Weekly Review Data** | Connect weekly review screen to actual DB data (currently uses hardcoded `_weekData` map) | Mixed |
| **Supabase Realtime** | Live sync via Supabase Realtime channels (currently uses poll-based LWW) | Online |

### Phase 3 — Platform Features (v0.4)

| Feature | Description | Offline/Online |
|---------|-------------|:--------------:|
| **Apple Watch Companion** | Quick energy check-in, MIT progress, active timer on wrist | Offline |
| **Android Wear Companion** | Same as Watch, using Wear OS Tiles | Offline |
| **Screen Time Integration** | Auto-detect scroll time via iOS Screen Time / Android Digital Wellbeing APIs | Offline |
| **Deep Link Handling** | Full URI scheme handling for widget taps and cross-app navigation (partially wired) | Offline |
| **Push Notifications** | Server-triggered notifications (streak at risk, weekly review ready) via FCM/APNs | Online |

### Phase 4 — Advanced Features (v0.5+)

| Feature | Description | Offline/Online |
|---------|-------------|:--------------:|
| **AI Energy Predictions** | ML model predicts optimal task scheduling based on energy patterns | Online |
| **Focus Mode OS Integration** | Trigger iOS Focus Mode / Android DND during Deep Work sessions | Offline |
| **Team/Accountability** | Shared goals, accountability partners, group streaks | Online |
| **Data Export** | Export all data as CSV/JSON for self-analysis | Offline |
| **Custom Sounds** | User imports their own ambient sound files from device | Offline |
| **Pomodoro Variations** | 52/17 DeskTime, Flowtime (flexible), custom intervals | Offline |
| **Calendar Integration** | Block deep work time in Google Calendar / Apple Calendar | Online |

---

## 5. Cost Analysis & Free/Cheap Alternatives

### Running Cost Breakdown

#### A. Backend Server (FastAPI AI Proxy)

| Provider | Tier | Cost/Month | Notes |
|----------|------|:----------:|-------|
| **Railway** (current default) | Hobby | **$5/mo** | Auto-sleep, 500 hrs/mo execution. Recommended for low traffic |
| **Render** | Free | **$0** | Spins down after 15 min inactivity (cold starts ~30s). Good for testing |
| **Fly.io** | Free | **$0** | 3 shared-1x VMs free. Good for always-on |
| **Vercel (Serverless)** | Hobby | **$0** | Would need to rewrite FastAPI as serverless functions. 100K invocations/mo free |
| **Self-hosted** (Raspberry Pi / old laptop) | — | **$0** | Needs port forwarding or Cloudflare Tunnel. Zero cost |

**Recommendation:** Start with **Render Free Tier** or **Fly.io Free** for testing. Upgrade to Railway ($5/mo) for production.

#### B. AI / LLM API (Gemini)

| Provider | Model | Free Tier | Paid Rate | Monthly Estimate |
|----------|-------|-----------|-----------|:----------------:|
| **Google AI Studio (Gemini)** | Gemini 2.0 Flash | **15 RPM, 1M tokens/day free** | $0.075/1M input tokens | **$0–$2/mo** (single user) |
| **Google AI Studio (Gemini)** | Gemini 2.5 Flash | **10 RPM, free tier** | $0.15/1M input tokens | **$0–$5/mo** |
| **OpenAI** | GPT-4o Mini | No free tier | $0.15/1M input | **$3–$10/mo** |
| **Anthropic** | Claude Haiku | No free tier | $0.25/1M input | **$5–$15/mo** |
| **Groq** | Llama 3.1 70B | **14,400 req/day free** | Free (rate-limited) | **$0** |
| **Ollama (self-hosted)** | Llama 3.1 8B | Unlimited (local) | $0 (hardware cost) | **$0** |

**Recommendation:** **Gemini 2.0 Flash free tier** is more than enough for a single user (you get 1 million tokens/day for free). Even with 20 AI calls/day (daily reports + brain dumps + break content), you'll use ~50K tokens — well within the free limit.

> **Total AI cost for personal use: $0/month**

#### C. Cloud Database (Supabase)

| Provider | Free Tier | Paid | Notes |
|----------|-----------|------|-------|
| **Supabase** | **500 MB database, 50K MAU auth, 1 GB storage** | $25/mo (Pro) | Free tier is generous for personal use |
| **Firebase** (Firestore) | 1 GiB storage, 50K reads/day | $0.06/100K reads | Would require rewriting sync layer |
| **Neon** (Serverless PostgreSQL) | 0.5 GB, always-on | $19/mo | Compatible with Supabase migrations |
| **PlanetScale** (MySQL) | Deprecated free tier | $39/mo | Not recommended |
| **SQLite Cloud** | 1 GB free | $10/mo | Direct SQLite sync — interesting future option |

**Recommendation:** **Supabase Free Tier**. 500 MB is massive for a single-user productivity app. You'd need years of data to approach that limit.

> **Total database cost for personal use: $0/month**

#### D. Total Monthly Cost Estimates

| Scenario | Backend | AI | Database | **Total** |
|----------|:-------:|:--:|:--------:|:---------:|
| **100% Offline** (no AI, no sync) | $0 | $0 | $0 | **$0** |
| **Personal Use** (free tiers) | $0 (Render/Fly) | $0 (Gemini free) | $0 (Supabase free) | **$0** |
| **Personal Use** (paid, reliable) | $5 (Railway) | $0 (Gemini free) | $0 (Supabase free) | **$5/mo** |
| **Small team** (5-10 users) | $5 (Railway) | $2 (Gemini paid) | $0 (Supabase free) | **$7/mo** |
| **Public launch** (100+ users) | $20 (Railway Pro) | $10 (Gemini) | $25 (Supabase Pro) | **$55/mo** |

### Cheapest Possible Stack (Fully Featured, $0/month)

| Component | Free Solution |
|-----------|--------------|
| Backend server | Render Free Tier (auto-sleeps, ~30s cold start) |
| AI model | Google Gemini 2.0 Flash free tier (15 RPM, 1M tokens/day) |
| Database | Supabase Free Tier (500 MB PostgreSQL) |
| Auth | Supabase Auth free (50K MAU) |
| File storage | Supabase Storage free (1 GB) |
| Monitoring | UptimeRobot free (5-min checks) |
| **Total** | **$0/month** |

---

## 6. Pre-Testing Readiness Audit (Offline)

### Methodology

I performed a systematic audit of every screen, service, and database interaction to verify offline testability. Below are the results.

### ✅ PASS — Ready for Offline Testing

| Component | Status | Evidence |
|-----------|:------:|---------|
| **Database initialization** | ✅ | `AppDatabase` opens SQLite via `path_provider`. In-memory mode works in tests. All 49 tests pass |
| **Main app entry** | ✅ | `main.dart` checks `SupabaseConfig.isConfigured` — skips Supabase init when no env vars provided |
| **GoRouter navigation** | ✅ | `appRouter` starts at `/home`. All 18 routes resolve without network |
| **Auth bypass** | ✅ | Auth screen has "Use offline (no sync)" → `context.go('/home')`. No forced login |
| **Task CRUD** | ✅ | `TasksDao` has full CRUD: `insertTask`, `completeTask`, `softDelete`, `toggleMIT`, `getAllActive` |
| **Morning Intention** | ✅ | Uses `db.dailyPlansDao.upsertToday()` — safe against duplicates |
| **Focus Timer (Pomodoro)** | ✅ | `FocusScreen` runs a local `Timer.periodic`, logs to `FocusSessions` table |
| **Deep Work Timer** | ✅ | `DeepWorkScreen` creates session in DB on start, awards XP on complete |
| **Focus Ritual** | ✅ | Checklist + breathing animation — awards XP via `XpCalculator` |
| **Shutdown Ritual** | ✅ | Marks `shutdownCompleted` in `DailyPlans`, awards XP |
| **XP Ledger** | ✅ | `TaskCompletionService` ensures consistent XP logging from any screen |
| **Daily Score** | ✅ | `DailyScoreCalculator` is pure math — no network calls |
| **Scroll Tracker** | ✅ | Timer + quick-log + recovery actions — all local |
| **Energy Check-ins** | ✅ | `EnergyCheckInsDao.insert()` → local SQLite |
| **Achievements** | ✅ | `AchievementChecker` queries local DAOs for badge conditions |
| **Profile Screen** | ✅ | Reads `xpLedgerDao.getLifetimeXP()` and computes level |
| **Settings** | ✅ | Sync button guarded by auth check. Theme/notifications are local |
| **Notifications** | ✅ | `flutter_local_notifications` — 100% on-device scheduling |
| **Home Widgets** | ✅ | `home_widget` package reads/writes local data |
| **Daily Report (data)** | ✅ | All metrics loaded from local DAOs |
| **Daily Report (AI fallback)** | ✅ | `DailyReportInsight.fallback()` provides static insight when AI unreachable |
| **Theme engine** | ✅ | Dark theme is complete. Level-gated theme unlocking works |
| **Flutter Analyze** | ✅ | 0 errors, 0 warnings (only 2 non-blocking `info` level notices) |
| **Flutter Test** | ✅ | 49/49 tests pass (XP constants, daily score calculator, widget smoke) |

### ⚠️ WARN — Works But Has Caveats

| Component | Issue | Impact | Severity |
|-----------|-------|--------|:--------:|
| **Google Fonts (Inter)** | `google_fonts` package fetches font files from Google's CDN on first use. If the device has never loaded the app with network access, text will render in the **system default sans-serif** instead of Inter | Visual mismatch — text looks different but is readable. Subsequent launches use cached fonts | **Low** |
| **JetBrains Mono** | Referenced as `fontFamily: 'JetBrainsMono'` in `AppTypography` but the font files are NOT bundled (fonts dir has `.gitkeep` only). The font section in `pubspec.yaml` is commented out | Timer digits and XP counters will render in the **system monospace fallback** instead of JetBrains Mono | **Low** |
| **Lottie/Rive Animations** | `lottie` and `rive` packages are declared in pubspec but the `assets/animations/` directory only contains `.gitkeep` | If any screen references a Lottie/Rive file, it will crash. Current screens use Flutter's built-in animation APIs instead, so this is safe for now | **Low** |
| **Brain Dump Screen** | AI call will fail offline → `_sortedTasks` stays `null` → the "processing" spinner shows indefinitely, then stops, with no tasks generated | User sees empty result after typing brain dump text. **No error message shown to explain why** | **Medium** |
| **Weekly Review Data** | Uses **hardcoded** `_weekData` map instead of querying actual database | Numbers displayed are fake placeholder data, not real user stats | **Medium** |

### ❌ FAIL — Will Not Work / Will Crash

| Component | Issue | Impact | Severity |
|-----------|-------|--------|:--------:|
| **Ambient Sounds** | `assets/sounds/` directory is empty (`.gitkeep` only). `AmbientSoundPlayer.play()` calls `_player.setAsset('assets/sounds/rain_loop.mp3')` which will throw a `PlayerException` | **App will show an error or silently fail** when user taps any ambient sound button during Deep Work | **🔴 P0** |
| **Image Assets** | `assets/images/` is empty (`.gitkeep`). If any screen tries to load an image asset, it will crash | Onboarding, profile, or achievement screens that reference image assets will fail | **Medium** — need to verify no code references image assets |

---

## 7. Blockers & Fixes Required Before Testing

### 🔴 P0 — Must Fix Before Testing

#### 1. Missing Ambient Sound Files

**Problem:** `assets/sounds/` is empty — all 4 sound files are missing.

**Required files:**
| File | Description | Duration | Format |
|------|-------------|----------|--------|
| `binaural_40hz.mp3` | 40Hz gamma binaural beats | 5–10 min (loops) | MP3, 128kbps |
| `rain_loop.mp3` | Rain/storm ambiance | 3–5 min (loops) | MP3, 128kbps |
| `cafe_ambiance.mp3` | Café chatter/background | 3–5 min (loops) | MP3, 128kbps |
| `forest_loop.mp3` | Forest birds/wind | 3–5 min (loops) | MP3, 128kbps |

**Sources for royalty-free loops:**
| Source | License | Cost | Quality |
|--------|---------|:----:|:-------:|
| **Freesound.org** | CC0 / CC-BY | Free | ★★★★ |
| **Pixabay Music** | Pixabay License (free commercial use) | Free | ★★★★ |
| **Zapsplat** | Standard License (free with attribution) | Free | ★★★ |
| **Epidemic Sound** | Subscription | $9/mo | ★★★★★ |
| **Artlist** | Subscription | $10/mo | ★★★★★ |
| **Generate with AI** | Google's MusicFX or Suno.ai | Free | ★★★ |

**Estimated total file size:** 8–15 MB for all 4 loops (at 128kbps, 3-5 min each).

**Solution Options:**
1. **(Recommended)** Download royalty-free loops from Freesound.org or Pixabay and place in `assets/sounds/`
2. **(Alternative)** Add a `try-catch` wrapper in `AmbientSoundPlayer.play()` to gracefully fail + show a snackbar instead of crashing. This lets the app launch without sounds while you source the files

#### 2. Missing JetBrains Mono Font Files

**Problem:** `assets/fonts/` is empty. `pubspec.yaml` has the font declaration commented out. Timer digits, XP counters, and stat numbers use `fontFamily: 'JetBrainsMono'` which will fall back to system monospace.

**Fix:**
1. Download JetBrains Mono from [jetbrains.com/lp/mono](https://www.jetbrains.com/lp/mono/) (free, OFL license)
2. Place `JetBrainsMono-Regular.ttf`, `JetBrainsMono-Medium.ttf`, `JetBrainsMono-Bold.ttf` in `assets/fonts/`
3. Uncomment the `fonts:` section in `pubspec.yaml` (lines 89-97)

### 🟡 P1 — Should Fix Before Testing

#### 3. Brain Dump Offline UX

**Problem:** If user types a brain dump and AI is unreachable, the screen shows a spinner, then nothing. No user-facing error message.

**Fix:** Add a snackbar or dialog when `processBrainDump()` returns `null`:
```dart
if (tasks == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('AI is offline. Add tasks manually on the Tasks screen.')),
  );
}
```

#### 4. Weekly Review Hardcoded Data

**Problem:** `weekly_review_screen.dart` uses a hardcoded `_weekData` map instead of querying the database.

**Fix:** Query `DailyPlans`, `FocusSessions`, `Tasks`, `XpLedger`, and `ScrollLogs` for the past 7 days, similar to how `DailyReportScreen._loadReport()` works.

#### 5. Google Fonts First-Load

**Problem:** `google_fonts` package will try to fetch Inter font on first app launch. On a truly offline first launch, the text renders in system sans-serif.

**Fix options:**
- **(Recommended)** Bundle Inter font files in `assets/fonts/` and register them in `pubspec.yaml`. Then switch `GoogleFonts.inter(...)` calls to use the bundled font family. This makes the app 100% offline from the very first launch.
- **(Alternative)** Accept the fallback — Inter looks very similar to system San Francisco (iOS) and Roboto (Android).

### 🟢 P2 — Nice To Have

#### 6. Image Assets

The `assets/images/` directory is empty. No current code appears to reference image assets directly (screens use emoji and Flutter icons instead), but it's worth confirming with a grep.

#### 7. Lottie/Rive Animations

Same situation as images — packages are in pubspec but no animation files exist. Current screens use custom Flutter `AnimationController` / `AnimatedBuilder` code instead. Safe for now.

---

## 8. Recommendations Summary

### Before Starting Offline Testing

| Priority | Action | Effort | Impact |
|:--------:|--------|:------:|:------:|
| 🔴 P0 | **Source and add 4 ambient sound MP3 files** to `assets/sounds/` | 30 min | Prevents crash in Deep Work |
| 🔴 P0 | **Download and bundle JetBrains Mono fonts** + uncomment pubspec.yaml font section | 10 min | Fixes timer digit rendering |
| 🟡 P1 | **Add offline error handling** to Brain Dump screen | 15 min | Better UX when AI unavailable |
| 🟡 P1 | **Wire Weekly Review to real DB data** | 45 min | Shows actual user stats, not fake data |
| 🟡 P1 | **Bundle Inter font** (optional — system fallback is acceptable) | 15 min | Guarantees correct typography on first offline launch |
| 🟢 P2 | Verify no code references missing image/animation assets | 10 min | Prevents potential crashes |

### After Fixing P0s — Testing Checklist

1. **Clean install** — delete app data, run `flutter run` without `--dart-define-from-file`
2. **Tap "Use offline (no sync)"** on auth screen
3. **Run through the full daily loop:**
   - Morning Intention → set 3 MITs
   - Create tasks on Tasks screen
   - Start a Deep Work session → test all 4 ambient sounds → complete
   - Check Break screen XP reveal
   - Log scroll time on Scroll Tracker
   - Log energy check-in
   - Run Shutdown Ritual
   - View Daily Report
   - Check Profile for XP and level
4. **Verify data persistence** — kill and relaunch the app, check data is still there
5. **Test edge cases** — double Morning Intention, complete MITs from both Home and Tasks screens

---

*This report was generated by analyzing every source file in the FlowOS codebase. For the complete implementation architecture, see [implementation_plan.md](file:///Users/dankmagician/Documents/New%20project/flowos/docs/implementation_plan.md).*
