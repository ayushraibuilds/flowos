<![CDATA[# FlowOS

> A personal operating system for time, energy, and attention.

**FlowOS** is an offline-first Flutter app (Android + iOS) built around a single loop: **intention → focused work → recovery → reflection.** It combines task management, focus timing, app blocking, energy tracking, scroll awareness, an XP/leveling system, and an evolving visual garden — all driven by the philosophy that software should reward effort, never punish inactivity.

---

## Table of Contents

- [Core Features](#core-features)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Android Native Services](#android-native-services)
- [Chrome Extension](#chrome-extension)
- [Backend API](#backend-api)
- [Database Schema](#database-schema)
- [Design System](#design-system)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Environment Variables](#environment-variables)
- [Permissions](#permissions)
- [Contributing](#contributing)
- [License](#license)

---

## Core Features

### 🎯 Morning Intention & Daily Planning
Set up to 3 Most Important Tasks (MITs), log your energy level (1–5), and define an attention budget before the day begins. The daily plan anchors every other system — focus sessions, scoring, and the AI report all reference what you intended to do.

### ⏱️ Focus Timer (Focus Cave)
Four session types, all growing a plant in your garden:

| Mode | Duration | Use Case |
|------|----------|----------|
| **Classic (Pomodoro)** | 25 min | Short, structured sprints |
| **DeskTime** | 52 min | Research-backed productivity cycle |
| **Deep Work** | 90 min | Extended, uninterrupted creative blocks |
| **Flowtime** | Open-ended | Count-up timer — stop when *you* decide |

Each session includes:
- **Ambient sounds** — Binaural beats, rain, café noise, piano, or silence
- **Live XP counter** — See effort accumulate in real time
- **Quality grading** — A/B/C based on pause count and app-background events
- **Breathing ring animation** — Subtle pulse synced to the timer
- **Garden seed growth** — Every session plants and grows a tree or flower

### 🛡️ App Blocking (Android)
Real-time, system-level app blocking powered by an Android `AccessibilityService`:

| Protection Level | Behavior |
|-----------------|----------|
| **Nudge** | Logs the distraction silently; no redirect |
| **Guard** | Redirects you to a shield overlay with a 20s countdown, then offers timed breaks (5/10/15 min) |
| **Deep** | Redirects with a 30s countdown; the *only* escape is cancelling the entire session |

Key design decisions:
- **Consent-based** — The user explicitly picks their protection level before starting
- **Essential apps always bypass** — Dialer, SMS, camera, system settings, and FlowOS itself are never blocked
- **Scoped breaks** — Guard mode allows per-app timed breaks (e.g., 5 min of Instagram) without disabling protection for other apps
- **Sleep mode blocking** — Separate schedule-based blocking for bedtime, with its own protected app list
- **Foreground service** — A native Android `ForegroundService` renews the blocking lease every 20 seconds independently of the Flutter isolate, surviving Doze mode and aggressive OEM battery managers

### 🌳 Flow Garden
A visual metaphor for your focus history. Each completed focus session grows a plant:
- **Short sessions** → flowers (🌸🌻🌷🌼)
- **Deep Work / long sessions** → trees (🌲🌳🌴)
- **Recovery actions** → water droplets (💧)
- **High-quality days** → wildlife visitors (🦋☀️)

The garden follows a **no-punishment philosophy**: inactive days show "resting soil" — your plants remain, nothing dies or decays.

### ⚡ Energy-Aware Task System
Tasks carry cognitive load metadata (`deep` / `medium` / `light`), making them matchable to your current energy level. Features include:
- **Recurrence** — Daily, weekday, weekly, monthly with smart date clamping (Jan 31 → Feb 28)
- **Brain Dump** — Free-form text input, auto-parsed into actionable tasks via a local NLP parser
- **Task Roulette** — Randomly surfaces a task when you're stuck deciding
- **Focus session linking** — Start a timer directly from a task card

### 🏆 XP & Leveling System
An **append-only XP ledger** (no retroactive deductions) with effort-based rewards:

| Action | XP |
|--------|-----|
| Complete a Pomodoro | 20 |
| Complete Deep Work | 40 |
| Complete a Flowtime session | ~1.6/min × quality multiplier |
| Partial session (≥60%, ≥10 min) | 50% base × progress |
| Complete a task | 10 |
| Morning intention set | 5 |
| Shutdown ritual done | 5 |

Leveling follows a gentle exponential curve. The system explicitly avoids "guiltware" — no negative XP, no punishment for inactivity, no streaks lost without a grace period.

### 🔥 Streak System
Consecutive days of activity build a streak. Designed with compassion:
- **1 day missed** → streak *paused* (grace day), not reset
- **2+ days missed** → streak resets to 1 on next activity
- **Best streak** tracked permanently
- **DST-safe** — Calendar-date comparison, not clock-arithmetic

### 📱 Scroll & Attention Tracking
Manual scroll logging with guided recovery actions (breathe, stretch, drink water). Feeds into the daily score's Attention pillar.

### 📊 Daily Score & Grading
A composite 0–100 score across four weighted pillars:

| Pillar | Weight | Source |
|--------|--------|--------|
| Focus | 35% | Minutes of focused work |
| Intent | 25% | MITs completed, intention set |
| Attention | 25% | Scroll budget adherence |
| Care | 15% | Recovery actions, energy check-ins |

Grade mapping: **A+ (90+) → A (80+) → B (70+) → C (55+) → D (40+) → F (<40).**  
Zero-engagement days show `—` (not scored yet) instead of a failing grade — because showing an F before someone has had a chance to do anything would be hostile.

### 🤖 AI Daily Report
End-of-day pattern recognition powered by Gemini Flash via a Python FastAPI backend. The report analyzes focus patterns, energy trends, and task completion — offering observations, not lectures.

### 🌙 Sleep Mode
Schedule-based distraction blocking during bedtime hours. Configurable per-weekday with its own protected app list and protection level (Nudge / Guard / Deep). Works alongside focus mode — whichever policy is stricter wins.

### 🔔 Notification Interruption Tracking
A `NotificationListenerService` counts notification volume per app per hour. Data feeds into insights about which apps interrupt you most.

### 🎨 Theming
Multiple dark themes (Midnight Emerald, Ocean Depth, Warm Charcoal, Forest Night) with dynamic color support via Material You on Android 12+.

### 📤 Data Export
Full database export to JSON — all 8+ tables with schema version and timestamps.

### 🏅 Achievements
Milestone-based unlocks tracked against cumulative stats (total focus hours, streak length, sessions completed, etc.). Shown as celebratory toasts with confetti.

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         FlowOS App (Flutter)                     │
│                                                                  │
│  ┌─────────┐  ┌──────────────┐  ┌───────────┐  ┌─────────────┐ │
│  │ Screens  │  │  Providers   │  │ Services  │  │  Database   │ │
│  │ (UI)     │←→│  (Riverpod)  │←→│ (Logic)   │←→│  (Drift/    │ │
│  │          │  │              │  │           │  │   SQLite)   │ │
│  └─────────┘  └──────────────┘  └───────────┘  └──────┬──────┘ │
│                                                        │        │
│  ┌─────────────────────────────────────────────────────┼──────┐ │
│  │                  Platform Channels                   │      │ │
│  └─────────────────────────────────────────────────────┼──────┘ │
└──────────────────────────────────────────────────────────┼──────┘
                                                          │
        ┌─────────────────────────────────────────────────┼──────┐
        │                 Android Native (Kotlin)          │      │
        │                                                  │      │
        │  ┌───────────────────┐  ┌────────────────────┐  │      │
        │  │ FocusBlockerService│  │ ForegroundService  │  │      │
        │  │ (Accessibility)    │  │ (Lease Renewer)    │  │      │
        │  └───────────────────┘  └────────────────────┘  │      │
        │  ┌───────────────────┐  ┌────────────────────┐  │      │
        │  │ NotificationTracker│  │ TriggerStore /     │  │      │
        │  │ Service            │  │ NudgeStore         │  │      │
        │  └───────────────────┘  └────────────────────┘  │      │
        └─────────────────────────────────────────────────┘      │
                                                                  │
        ┌─────────────────────────────────────────────────┐      │
        │              Supabase (Optional Cloud Sync)      │←─────┘
        │  Auth · Realtime · PostgreSQL · Row-Level Security│
        └─────────────────────────────────────────────────┘
                              ↕
        ┌─────────────────────────────────────────────────┐
        │             Python Backend (FastAPI)              │
        │  Gemini Flash AI · Daily Reports · Rate Limiting  │
        └─────────────────────────────────────────────────┘
                              ↕
        ┌─────────────────────────────────────────────────┐
        │          Chrome Extension (Manifest V3)           │
        │  Browsing session tracking · Site blocking         │
        │  Cross-device focus sync · Side panel dashboard    │
        └─────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Framework** | Flutter 3.41+ | Cross-platform UI (Android + iOS) |
| **State Management** | Riverpod 2.6 | Reactive providers, dependency injection |
| **Local Database** | Drift 2.34 (SQLite) | Offline-first persistent storage |
| **Cloud Sync** | Supabase | Auth (Apple/Google/Email), Realtime, PostgreSQL |
| **Navigation** | GoRouter 14.8 | Declarative routing with deep link support |
| **AI Backend** | FastAPI + Gemini Flash | Daily report generation |
| **Charts** | fl_chart 0.70 | Dashboard visualizations |
| **Animations** | flutter_animate, Rive | Micro-animations, celebration effects |
| **Audio** | just_audio | Ambient focus sounds |
| **Notifications** | flutter_local_notifications | Reminders, nudges |
| **Extension** | Chrome Manifest V3 | Browser-side tracking and blocking |
| **Typography** | Inter + JetBrains Mono | Bundled TTF assets (no runtime font loading) |

---

## Project Structure

```
flowos/
├── lib/
│   ├── main.dart                  # App entry point, Supabase/notification init
│   ├── core/
│   │   ├── config/                # Supabase config, environment constants
│   │   ├── constants/             # XP formulas, spacing tokens
│   │   └── theme/                 # AppColors, AppTypography, AppTheme, AppSpacing
│   ├── data/
│   │   └── local/
│   │       ├── database/          # Drift AppDatabase + generated code
│   │       └── tables/            # 18 table definitions (tasks, sessions, XP, etc.)
│   ├── domain/                    # Repository interfaces, shared models
│   ├── features/
│   │   ├── achievements/          # Achievement definitions + checker
│   │   ├── ai/                    # Gemini AI report integration
│   │   ├── attention/             # Usage stats, device attention platform channel
│   │   ├── auth/                  # Supabase auth service + providers
│   │   ├── celebration/           # Confetti, toasts, level-up animations
│   │   ├── dashboard/             # Daily score calculator, dashboard providers
│   │   ├── energy/                # Energy check-in service
│   │   ├── export/                # JSON data export
│   │   ├── flow_garden/           # Garden day model, growth logic, painters
│   │   ├── focus/                 # Timer notifier, session service, policy writer,
│   │   │                          #   shield overlay, protection models
│   │   ├── insights/              # Unlock attempt aggregation, usage patterns
│   │   ├── notifications/         # Local notification scheduling
│   │   ├── onboarding/            # Multi-step onboarding flow + profile setup
│   │   ├── reports/               # Daily report generation + history
│   │   ├── rhythm/                # Rhythm engine (optimal work/break scheduling)
│   │   ├── settings/              # User preferences, focus protection level
│   │   ├── sync/                  # Supabase sync engine + outbox pattern
│   │   ├── tasks/                 # Task CRUD, recurrence, brain dump parser
│   │   ├── themes/                # Multiple dark themes (Midnight Emerald, etc.)
│   │   ├── usage/                 # Usage stats service
│   │   ├── wellbeing/             # Scroll tracking, recovery actions
│   │   ├── widgets/               # Home screen widgets (Android)
│   │   └── xp/                    # XP constants, level formulas, streak service
│   └── presentation/
│       ├── navigation/            # GoRouter config, route guards
│       └── screens/               # 18 screen groups (home, focus, tasks, etc.)
├── android/
│   └── app/src/main/kotlin/.../
│       ├── MainActivity.kt                  # Platform channel handler
│       ├── FocusBlockerService.kt           # Accessibility-based app blocker
│       ├── FocusSessionForegroundService.kt # Native lease renewer
│       ├── NotificationTrackerService.kt    # Notification listener
│       ├── TriggerStore.kt                  # Atomic blocked-app trigger store
│       └── NudgeStore.kt                    # Nudge event persistence
├── backend/                       # Python FastAPI server
│   ├── main.py                    # App entry, CORS, rate limiting
│   ├── routers/                   # API endpoints (daily reports)
│   ├── services/                  # Gemini AI integration
│   ├── prompts/                   # LLM prompt templates
│   └── tests/                     # Backend unit tests
├── flowos-extension/              # Chrome Extension (Manifest V3)
│   ├── manifest.json              # Extension config
│   ├── service-worker.js          # Background sync, focus state, blocking
│   ├── blocked.html/js            # Block page with escape hatch
│   ├── popup/                     # Extension popup UI
│   ├── sidepanel/                 # Side panel dashboard
│   └── options/                   # Pairing + settings
├── supabase/
│   └── migrations/                # 4 SQL migration files
├── test/                          # 27 test files, 150+ test cases
│   ├── widget/                    # Widget tests
│   ├── unit/                      # Unit tests
│   └── integration/               # Integration tests
├── docs/
│   └── FLOWOS_IMPLEMENTATION_PLAN.md  # Detailed audit & roadmap
└── .github/workflows/
    └── flutter_ci.yml             # GitHub Actions CI pipeline
```

---

## Getting Started

### Prerequisites

- **Flutter** 3.41+ (stable channel)
- **Dart** SDK 3.11+
- **Android Studio** or **VS Code** with Flutter extensions
- **Java 17** (for Android builds)
- **Python 3.10+** (for backend, optional)

### 1. Clone & Install

```bash
git clone https://github.com/ayushraibuilds/flowos.git
cd flowos
flutter pub get
```

### 2. Run in Local-Only Mode (No Backend Required)

```bash
flutter run
```

The app works fully offline with local SQLite storage. Supabase sync and AI reports are optional features.

### 3. Run with Supabase Sync (Optional)

```bash
# Copy and fill in your Supabase credentials
cp .env.example .env

# Run with environment variables
flutter run --dart-define-from-file=.env
```

### 4. Build Release APK

```bash
flutter build apk
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 5. Start the Backend (Optional)

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env  # Add your GEMINI_API_KEY
uvicorn main:app --reload
```

---

## Android Native Services

FlowOS uses four native Android services for features that require running outside the Flutter isolate:

### FocusBlockerService (Accessibility Service)
- **Purpose**: Monitors foreground app changes and redirects users away from blocked apps
- **Activation**: User must manually enable in Android Settings → Accessibility
- **Policy source**: Reads `flowos_active_policies` from SharedPreferences (written by Flutter)
- **Smart bypass**: Never blocks the dialer, SMS, camera, system UI, launchers, or FlowOS itself
- **Dual-policy**: Evaluates both Focus and Sleep policies simultaneously; stricter wins

### FocusSessionForegroundService
- **Purpose**: Renews the blocking lease (`activeUntil` timestamp) from native code every 20 seconds
- **Why native**: Dart timers are throttled/killed when the app is backgrounded or in Doze mode
- **Notification**: Shows a persistent low-priority notification: "Focus session is running"
- **Lifecycle**: Started via platform channel when a focus/sleep session begins; stopped when it ends

### NotificationTrackerService (NotificationListenerService)
- **Purpose**: Counts notification events per app per hour for interruption tracking
- **Privacy**: Only records package name, timestamp, and count — never notification content

### TriggerStore / NudgeStore
- **Purpose**: Atomic, cross-process SharedPreferences stores for communicating between the AccessibilityService and the Flutter UI
- **Debouncing**: Built-in deduplication (1.5s package debounce, 2s redirect rate limit, 60s trigger expiry)

---

## Chrome Extension

The FlowOS Chrome Extension (Manifest V3) extends focus protection to the browser:

- **Browsing session tracking** — Records time spent per domain, syncs to Supabase
- **Site blocking** — Redirects to a focus shield page when visiting blocked sites during a focus session
- **Cross-device focus sync** — Polls Supabase for active focus sessions started on mobile, arms browser-side blocking automatically
- **Side panel** — Dashboard showing browsing patterns
- **Pairing** — QR-code or manual pairing with the mobile app via shared Supabase project

```bash
# Load as unpacked extension
# 1. Open chrome://extensions
# 2. Enable Developer Mode
# 3. Click "Load unpacked" → select flowos-extension/
```

---

## Backend API

A lightweight Python FastAPI server that handles AI-powered features:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/daily-report` | POST | Generate AI daily report via Gemini Flash |
| `/health` | GET | Health check |

**Key design decisions:**
- **Gemini API key stays server-side** — Never shipped in the Flutter binary
- **JWT validation** — Verifies Supabase auth tokens
- **Rate limiting** — Via `slowapi` to prevent abuse
- **CORS** — Configured for the Flutter app's origins

---

## Database Schema

### Local (Drift/SQLite) — 18 Tables

| Table | Purpose |
|-------|---------|
| `tasks` | Task CRUD with recurrence, cognitive load, completion state |
| `focus_sessions` | Session records with type, duration, quality, XP, garden seed data |
| `xp_ledger_entries` | Append-only XP transaction log |
| `daily_plans` | Morning intention, MITs, energy level, shutdown state |
| `daily_scores` | Cached composite scores per day |
| `daily_reports` | AI-generated report text + metadata |
| `energy_checkins` | Timestamped energy level logs |
| `scroll_logs` | Manual scroll tracking entries |
| `device_usage_records` | Per-app foreground usage minutes (from UsageStatsManager) |
| `device_day_metrics` | Aggregated daily device metrics (total screen time, unlocks) |
| `notification_daily_counts` | Per-app notification volume per hour |
| `protected_apps` | User's focus/sleep-protected app list |
| `sleep_schedules` | Bedtime/wake schedule per weekday |
| `unlock_attempts` | Blocked-app interaction logs (package, intention, outcome) |
| `achievements` | Unlocked achievement keys + timestamps |
| `attention_costs` | Per-app attention cost classification |
| `processed_notification_batches` | Deduplication for notification tracking |
| `sync_outbox` | Pending Supabase sync entries (outbox pattern) |

### Cloud (Supabase/PostgreSQL)
Mirrors the local schema with Row-Level Security policies. Sync uses an **outbox pattern** — local writes are queued and pushed in batches, with conflict resolution by device ID and timestamp.

---

## Design System

### Color Palette (Midnight Emerald — Default)

| Token | Hex | Usage |
|-------|-----|-------|
| `background0` | `#0A0E14` | Deepest background (near-black, blue undertone) |
| `background1` | `#121820` | Main content areas |
| `background2` | `#1A2230` | Cards, bottom sheets |
| `background3` | `#222E3E` | Modals, tooltips |
| `emerald` | `#00D68F` | Primary accent — XP, CTAs, positive actions |
| `focusBlue` | `#4E8AFF` | Focus timer ring, active states |
| `dangerCoral` | `#FF6B6B` | Stop buttons, warnings |
| `amber` | `#FFB84D` | Caution, medium-priority |

### Glass Surfaces (3-Tier Glassmorphism)

| Tier | Opacity | Blur | Use Case |
|------|---------|------|----------|
| Standard | 72% | 18px | Cards, list items |
| Elevated | 80% | 24px | Modals, focus timer |
| Floating | 85% | 30px | XP reveal, level-up overlay |

### Typography

| Style | Font | Weight | Size |
|-------|------|--------|------|
| Display | Inter | Bold (700) | 28sp |
| Headings (h1–h3) | Inter | Bold/SemiBold | 24/20/17sp |
| Body | Inter | Regular (400) | 15sp |
| Mono (timers, XP) | JetBrains Mono | Medium (500) | 32sp / 13sp |
| Caption | Inter | Regular | 12sp |

---

## Testing

**151+ test cases** across 27 test files:

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/focus_timer_stage_test.dart

# Run with coverage
flutter test --coverage
```

### Test Coverage Areas

| Area | Tests | Key Scenarios |
|------|-------|---------------|
| Focus Timer | 9 | Start/stop/pause lifecycle, seed generation, stale session recovery, process death hydration |
| Focus Session Pipeline | 2 | XP calculation, database transaction handling |
| Protection Policy | 10 | Policy activation/deactivation, scoped breaks, Focus+Sleep conflict resolution |
| Daily Score Calculator | 8 | Formula accuracy, grade boundaries, edge cases (zero input, negative values) |
| Streak Service | 7 | Consecutive days, grace period, DST boundary handling |
| Task Recurrence | 5 | Daily/weekday/weekly/monthly spawning, month-end clamping |
| Garden Service | 2 | Tree growth from Deep Work, wildlife from quality days |
| Onboarding Flow | 1 | Profile setup state transitions |
| Router Redirects | 5 | Auth guards, onboarding gates, deep link handling |
| XP Constants | 3 | Level formula, inverse computation |
| Widget Tests | 7 | Home screen rendering, app picker, flow surface |
| Data Export | 1 | Full-schema JSON serialization |

### Backend Tests

```bash
cd backend
pytest tests/
```

---

## CI/CD

GitHub Actions runs on every push and PR to `main`:

```yaml
# .github/workflows/flutter_ci.yml
- flutter pub get
- flutter analyze    # Static analysis
- flutter test       # All 151+ tests
```

---

## Environment Variables

### Flutter App (`.env`)

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
FLOWOS_API_URL=http://localhost:8000
```

Pass to Flutter via:
```bash
flutter run --dart-define-from-file=.env
```

### Backend (`backend/.env`)

```bash
GEMINI_API_KEY=your_gemini_api_key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key
```

---

## Permissions

### Android

| Permission | Purpose | Required |
|-----------|---------|----------|
| `PACKAGE_USAGE_STATS` | Read per-app screen time for usage tracking | Optional — app works without it |
| `BIND_ACCESSIBILITY_SERVICE` | Real-time app blocking during focus/sleep sessions | Optional — blocking feature only |
| `BIND_NOTIFICATION_LISTENER_SERVICE` | Count notification interruptions per app | Optional — insights feature only |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_SPECIAL_USE` | Keep blocking lease alive in background | Required for blocking reliability |
| `POST_NOTIFICATIONS` | Reminders, focus session status | Optional |

All sensitive permissions are requested explicitly with explanation screens during onboarding. The app is fully functional in "manual mode" without any of the optional permissions.

---

## Philosophy

FlowOS is built on a few non-negotiable principles:

1. **No guiltware** — The app never punishes inactivity. No dying pets, no guilt-trip notifications, no negative XP. An inactive day shows "resting soil" in the garden, not a graveyard.

2. **Consent-based protection** — Every intervention (blocking, pausing, nudging) is explicitly chosen by the user before the session starts. Nothing is imposed.

3. **Offline-first** — Full functionality with zero network connectivity. Cloud sync is a convenience, not a dependency.

4. **Effort over outcomes** — XP rewards showing up and trying, not just completing tasks. A 90-minute Deep Work session with 0 tasks completed still earns full XP.

5. **Transparency** — The escape hatch exists. The user can always stop a session. The system's job is to add friction to impulsive exits, not to imprison.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add your feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

Please ensure all tests pass (`flutter test`) and the analyzer is clean (`flutter analyze`) before submitting.

---

## License

This project is proprietary. All rights reserved.

---

*Built with intention.*
]]>
