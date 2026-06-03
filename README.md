# FlowOS

> A personal operating system for time, energy, and attention.

**FlowOS** is built around the loop: **intention → focused work → recovery → reflection.** It's not a todo app — it manages tasks, energy, and attention together, rewards effort over checkbox-ticking, and uses AI for pattern recognition rather than judgement.

## Core Features (v1)

- 🎯 **Morning Intention** — Pick 3 MITs + set energy level + attention budget
- ⏱️ **Focus Timer** — Pomodoro / Deep Work / Flowmodoro with ambient sounds
- ⚡ **Energy-Aware Tasks** — Tasks carry cognitive load (Deep / Medium / Light)
- 🏆 **XP System** — Append-only ledger, effort-based rewards, no guiltware
- 📱 **Scroll Tracking** — Manual logging with recovery actions
- 📊 **AI Daily Report** — Pattern recognition, not lectures (Gemini Flash)
- 🌳 **Flow Garden** — Visual metaphor for focus sessions
- 🔥 **Streak System** — Grace days (1 miss = pause, 2 = reset)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.41+ (iOS + Android) |
| State | Riverpod |
| Local DB | Drift (SQLite) |
| Backend | Supabase (Auth + Sync) |
| AI | Gemini Flash (Google AI Studio) |
| Extension | Chrome Extension (Manifest V3) |

## Architecture

```
lib/
├── core/           # Theme, constants, utilities, shared widgets
├── domain/         # Models, repository interfaces, services
├── data/           # Database, API, repository implementations
├── presentation/   # Screens, widgets, navigation
└── features/       # XP, achievements, flow garden, wellbeing, AI
```

## Design

- **Dark-first** — Midnight Emerald (#0A0E14 + #00D68F)
- **Glassmorphism** — 3-tier card system with BackdropFilter
- **Calm gamification** — Satisfying when earned, serene at rest
- **Typography** — Inter + JetBrains Mono

## Getting Started

```bash
flutter pub get
flutter run
```

## Status

🌱 **Phase 0** — Project scaffold complete. Design system tokens implemented.

---

*Built with intention.*
