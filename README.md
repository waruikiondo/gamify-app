# Gamify

A cyberpunk-themed, gamified IT certification learning platform built with Flutter and Supabase. Users progress through sequential learning levels, take timed mock exams, track skill mastery, compete on a global leaderboard, and earn a downloadable PDF certificate on completion.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.41.2 / Dart 3.11.0 |
| Backend | Supabase (Auth, PostgreSQL, Storage, RPC) |
| State Management | Flutter Riverpod |
| Navigation | GoRouter |
| Font | Google Fonts — Inter |
| PDF Generation | `pdf` + `printing` |
| Image Loading | `cached_network_image` |
| Env Config | `flutter_dotenv` |

---

## Project Structure

```
gamify-app-1/
├── .env                          # Supabase credentials (not committed)
├── pubspec.yaml                  # Dependencies & asset declarations
├── supabase/
│   └── migrations/
│       └── 0001_initial_schema.sql   # Full DB schema
├── exam_parser/
│   └── process_exam.py           # Python script to bulk-import exam PDFs into Supabase
└── lib/
    ├── main.dart                 # App entry point — loads .env, inits Supabase, runs app
    ├── core/
    │   ├── theme.dart            # Global dark theme (neon purple + cyan, Inter font)
    │   └── router.dart           # GoRouter config — all routes + auth redirect guards
    ├── models/
    │   └── level.dart            # Level data model (id, title, order, passingPercentage, markdown)
    ├── providers/
    │   ├── auth_provider.dart    # Auth state machine (Initial/Loading/Authenticated/Recovery/Error)
    │   ├── game_state_provider.dart  # Level evaluation + next-level unlock logic
    │   └── global_providers.dart # userJourney, skillMastery, leaderboard, finalExamStatus
    ├── services/
    │   ├── supabase_service.dart # All Supabase DB/auth operations (single source of truth)
    │   └── analytics_service.dart# Event tracking (level complete, certificate download, etc.)
    └── screens/
        ├── splash_screen.dart          # Boot animation + auth routing gateway
        ├── login_screen.dart           # Email/password login
        ├── signup_screen.dart          # Registration with real-time password strength meter
        ├── forgot_password_screen.dart # Sends Supabase password reset email
        ├── update_password_screen.dart # Handles deep-link recovery flow
        ├── goal_selection_screen.dart  # First-login: user picks their learning role/goal
        ├── dashboard_screen.dart       # Main shell — 4-tab layout (Home/Explore/Rank/Profile)
        ├── explore_screen.dart         # Visual level map — all chapters with lock/unlock state
        ├── rank_screen.dart            # Global leaderboard with top-3 podium
        ├── profile_screen.dart         # User profile, avatar upload, sign out, admin easter egg
        ├── level_overview_screen.dart  # Mission briefing — markdown content before assessment
        ├── level_screen.dart           # Live MCQ assessment with progress bar + skill tracking
        ├── mock_exam_screen.dart       # Final boss: timed 60-min exam, confetti on pass
        ├── admin_dashboard_screen.dart # Admin panel: manage levels and questions
        └── widgets/
            ├── custom_text_field.dart  # Reusable styled input field
            └── primary_button.dart     # Reusable primary CTA button
```

---

## Major Pages

| Screen | File | Route |
|---|---|---|
| Splash / Boot | `splash_screen.dart` | `/` |
| Login | `login_screen.dart` | `/login` |
| Sign Up | `signup_screen.dart` | `/signup` |
| Forgot Password | `forgot_password_screen.dart` | `/forgot-password` |
| Update Password | `update_password_screen.dart` | `/update-password` |
| Goal Selection | `goal_selection_screen.dart` | `/goal-selection` |
| Dashboard (Home) | `dashboard_screen.dart` | `/dashboard` |
| Explore (Level Map) | `explore_screen.dart` | tab inside dashboard |
| Leaderboard | `rank_screen.dart` | tab inside dashboard |
| Profile | `profile_screen.dart` | tab inside dashboard |
| Mission Briefing | `level_overview_screen.dart` | `/level/:levelId` |
| Assessment | `level_screen.dart` | `/level/:levelId/assessment` |
| Mock / Final Exam | `mock_exam_screen.dart` | `/mock-exam` |
| Admin Panel | `admin_dashboard_screen.dart` | `/admin` |

---

## App Flow

```
App Launch
    └── SplashScreen (2s animation + Supabase auth resolution)
            │
            ├── No session ──────────────────→ LoginScreen
            │                                       │
            │                               ┌───────┴───────┐
            │                           SignupScreen   ForgotPasswordScreen
            │                                               │
            │                                       UpdatePasswordScreen
            │                                       (via deep-link email)
            │
            ├── Session exists, no goal ────→ GoalSelectionScreen
            │                                   (Cloud Architect / Cyber Specialist / etc.)
            │                                       │
            │                                       ▼
            └── Session exists, goal set ───→ DashboardScreen
                                                    │
                                    ┌───────────────┼───────────────┐
                                 HomeTab        ExploreTab      RankTab    ProfileTab
                                    │               │
                             Progress ring     Level map
                             Streak badge      (all chapters,
                             Skill mastery      locked/unlocked)
                             "Up Next" card          │
                                    │                │
                                    └────────────────┘
                                             │
                                             ▼
                                    LevelOverviewScreen
                                    (Mission briefing markdown)
                                             │
                                             ▼
                                    LevelScreen (MCQ assessment)
                                    - Progress bar
                                    - Answer → feedback + explanation
                                    - Tracks skill area attempts
                                             │
                                    ┌────────┴────────┐
                                  Pass              Fail
                                    │                │
                              Next level         Retry same
                              unlocked           level
                              → Dashboard
                                    │
                          (All levels complete)
                                    │
                                    ▼
                            MockExamScreen
                            (60 min timed, 20 questions, confetti on pass)
                                    │
                                  Pass
                                    │
                            Certificate unlocked
                            (view + download PDF from Dashboard)
```

---

## Key Features

**Gamified Learning**
- Sequential locked levels — each unlocked only after passing the previous one at the required score threshold
- Real-time skill mastery scores per domain (via Supabase RPC `get_user_skill_mastery`)
- Daily streak tracking with share-to-social capability

**Assessment Engine**
- Multiple-choice questions with optional image attachments (cached for performance)
- Per-question explanations shown immediately after submission
- Skill area tracked per attempt for mastery calculation

**Final Exam**
- 60-minute countdown timer
- 20 randomly shuffled questions drawn from the full question bank
- Confetti animation on pass; 24-hour cooldown on fail
- Generates and downloads a PDF certificate of completion (landscape A4)

**Leaderboard**
- Real users blended with 5 seeded bot rivals to populate the podium from day one
- Current user always pinned at the bottom if not in top 50

**Admin Panel**
- Accessible via a 5-tap easter egg on the Profile screen (server-side admin check)
- Create/manage levels and questions directly from the app
- Route-guarded — non-admins who type `/admin` manually are immediately redirected

**Design System**
- Cyberpunk dark theme: deep `#12101C` background, neon purple `#8A2BE2` primary, cyan accents
- Inter font throughout
- Consistent card/surface hierarchy using `#1E1C2A` surfaces and `#2C2A3A` borders

---

## Database Tables (Supabase)

| Table | Purpose |
|---|---|
| `users` | Extended profiles — name, goal, streak, admin flag |
| `profiles` | Public-facing profile data — total score, avatar URL, title |
| `levels` | Chapter definitions — title, order, passing threshold, markdown content |
| `questions` | MCQ bank — linked to level + skill area, with image URL + explanation |
| `skill_areas` | Taxonomy of skill domains |
| `user_level_progress` | Per-user level unlock/completion state and high score |
| `user_question_attempts` | Per-question pass/fail history (used by mastery RPC) |
| `exam_results` | Mock exam results — score, time, pass/fail |

---

## Getting Started

### Prerequisites

- Flutter 3.41.2+ / Dart 3.11.0+
- A Supabase project with the schema from `supabase/migrations/0001_initial_schema.sql`

### Setup

```bash
# 1. Clone and install dependencies
flutter pub get

# 2. Create .env in the project root
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# 3. Run on web
flutter run -d chrome

# 4. Run on Android (ensure NDK 28.x is installed via Android Studio SDK Manager)
flutter run -d <device-id>
```

### Exam Content Import

To bulk-import exam questions from PDF:

```bash
cd exam_parser
pip install -r requirements.txt  # if not already done
SUPABASE_URL=... SUPABASE_SERVICE_KEY=... python process_exam.py
```

---

## Environment Notes

| Item | Status |
|---|---|
| `~/.cursor/mcp.json` Dart MCP | Configured (`command: dart`, args split correctly) |
| Active Dart | `/Users/.../Downloads/flutter/bin/dart` — v3.11.0 |
| Flutter | 3.41.2 stable |
| Android NDK | 27.x + 28.x both installed with valid `source.properties` |
| JAVA_HOME | `/opt/homebrew/opt/openjdk@17` — add to `~/.zprofile` to persist |
| Android SDK | v34 installed — Flutter 3.41.2 requires SDK 36 (upgrade pending) |
| Web (Chrome) | Fully working |
