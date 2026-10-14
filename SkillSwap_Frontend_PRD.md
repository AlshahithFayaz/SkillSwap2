
# SkillSwap — Frontend Product Requirements Document (PRD)

**App Name:** SkillSwap (Student Skill Exchange Platform)
**Slogan:** *Teach One Skill. Learn Another. Grow Together.*
**Platform:** Android (mobile-first), delivered as an installable APK
**Document Scope:** Frontend (UI/UX, screens, components, state, mock data, build)
**Version:** 1.0

---

## 1. Overview

SkillSwap is a peer-to-peer (P2P) skill exchange mobile app for college students. Students trade knowledge directly with each other, with no money involved.

**Example:** A student who knows Python but wants to learn Figma/UI Design is matched with a student who knows Figma but wants to learn Python. The two connect and teach each other for free.

### 1.1 Goals
- Let students list what they can teach and what they want to learn.
- Automatically match students with complementary skills and show a compatibility score.
- Allow a request-and-accept flow before any interaction begins.
- Provide 1-on-1 chat between accepted partners to schedule study sessions.
- Let partners rate and review each other after a session.
- Ship a polished, demo-ready APK for the college final review.

### 1.2 Non-Goals (v1)
- No payments, wallets, or monetization.
- No video/voice calls.
- No group classes.
- No admin panel.

### 1.3 Target Users
College students (all departments, all years) who want to learn new skills from peers.

---

## 2. Design System

### 2.1 Theme
Modern, clean, mobile-first with a **deep teal** identity.

| Token | Value | Usage |
|---|---|---|
| `primary` | `#0D9488` (teal) | Buttons, active nav, headers |
| `primary-dark` | `#0F766E` | Gradients, app bar |
| `accent` | `#06B6D4` (cyan) | Highlights, match ring |
| `teach` (green) | `#16A34A` bg `#DCFCE7` | "Skills I Teach" chips |
| `learn` (amber) | `#F59E0B` bg `#FEF3C7` | "Skills I Want to Learn" chips |
| `success` | `#16A34A` | Accepted status |
| `warning` | `#F59E0B` | Pending status |
| `danger` | `#DC2626` | Rejected status |
| `bg` | `#F8FAFC` | Screen background |
| `surface` | `#FFFFFF` | Cards |
| `text` | `#0F172A` / `#64748B` | Primary / secondary text |

**Brand gradient:** `#0F766E → #0D9488 → #06B6D4` (top-left to bottom-right).

### 2.2 Typography
- Font: **Inter** (fallback: system sans-serif).
- Scale: Title 24/700, Heading 18/600, Body 14/400, Caption 12/400.

### 2.3 Shape, Spacing, Elevation
- Base spacing unit: 4 px (use 8, 12, 16, 24).
- Card radius: 16 px. Button radius: 12 px. Chip radius: 999 px.
- Soft shadows on cards. Minimum touch target 44×44 px.

### 2.4 Core Components
- `Button` (primary, secondary, ghost, destructive; loading and disabled states)
- `Input` / `Select` (label, helper text, error state)
- `SkillChip` (variants: teach = green, learn = amber; removable and read-only)
- `MatchCard` (avatar, name, dept/year, score ring, teach/learn chips, CTA)
- `ScoreRing` (circular progress showing match %)
- `StatusBadge` (Pending / Accepted / Rejected)
- `ChatBubble` (sent / received, timestamp)
- `StarRating` (interactive 1–5)
- `BottomNav` (fixed)
- `EmptyState`, `Skeleton` loaders, `Toast`

---

## 3. Information Architecture and Navigation

**Fixed bottom navigation bar** (visible on all main screens):

| Tab | Icon | Screen |
|---|---|---|
| Home | house | Matches feed |
| Matches | handshake/swap | Exchange requests (Pending / Accepted / Rejected) |
| Chat | message | Conversations list |
| Profile | user | My profile and skills |

**Flow:**
`Splash → Login/Register → (Onboarding: add skills) → Home`
`Home → Match Detail → Connect & Swap → Matches (Pending)`
`Matches (Accepted) → Chat → Session → Rate & Review`

Auth screens hide the bottom nav. Chat conversation and rating screens are full-screen (nav hidden).

---

## 4. Screen Specifications

### 4.1 Splash Screen
- Gradient background, logo, app name "SkillSwap", slogan.
- Auto-navigates after ~1.5 s (to Home if logged in, otherwise Login).

### 4.2 Login and Registration
**Login:** college email, password, "Log in" button, link to "Register".

**Register form fields:**
| Field | Type | Validation |
|---|---|---|
| Full name | Text | Required |
| College email | Email | Required; must be a valid email (optionally restricted to college domain) |
| Roll number | Text | Required, unique |
| Department | Dropdown | AI&DS, CSE, IT, ECE, EEE, MECH, CIVIL, Other |
| Year | Dropdown/segmented | 1st, 2nd, 3rd, 4th |
| Password | Password | Min 6 chars, show/hide toggle |

- Inline error messages; submit disabled until the form is valid.
- On success, go to **Skill Onboarding** (4.3).

### 4.3 Skill Inventory (Onboarding and Profile Editing)
Two sections:
1. **Skills I Teach** — **green chips**
2. **Skills I Want to Learn** — **yellow/orange chips**

Features:
- Searchable skill picker with suggestions (Python, Java, Figma, UI/UX, React, SQL, Excel, Canva, Video Editing, Public Speaking, Data Structures, Machine Learning, etc.).
- Add custom skill by typing.
- Remove a chip with an "×" tap.
- Validation: at least 1 skill in each list to continue.

### 4.4 Home (Smart Matching Feed)
- Header: greeting ("Hi, {name}"), notification icon.
- Search bar and filter chips (Department, Year, Skill).
- Vertical list of **MatchCards**, sorted by compatibility score (highest first).

**MatchCard contents:**
- Avatar (initials fallback), name, department • year
- **Compatibility Score ring** (e.g., 85% Match)
- "Teaches you:" green chips (their Teach ∩ my Learn)
- "Wants from you:" amber chips (their Learn ∩ my Teach)
- **"Connect & Swap"** primary button

States: loading skeletons, empty ("No matches yet — add more skills"), error with retry.
After tapping Connect & Swap, the button changes to "Request Sent" (disabled) and a toast confirms.

### 4.5 Match Detail (optional drill-down)
- Full profile, both skill lists, rating average and reviews, score breakdown, Connect & Swap CTA.

### 4.6 Exchange Requests (Matches Tab)
Segmented tabs: **Pending | Accepted | Rejected**

| Status | Badge | Available Actions |
|---|---|---|
| Pending (incoming) | Amber | Accept, Reject |
| Pending (outgoing) | Amber | Cancel request |
| Accepted | Green | Open Chat, Mark Session Complete |
| Rejected | Red | None (read-only) |

**Rule:** Only **Accepted** partners can access Chat and Rating. Chat/Rate buttons are hidden or disabled for Pending and Rejected requests.

### 4.7 Chat
**Conversation list:** accepted partners only; avatar, name, last message, time, unread dot.

**Conversation screen (WhatsApp-style):**
- Top bar: back, avatar, name, partner's skill exchange summary.
- Bubbles: sent (right, primary color), received (left, light grey), timestamps.
- Auto-scroll to latest message; input bar with send button (disabled when empty).
- Purpose: fix the study schedule. Optional quick-reply chips ("Tomorrow 5 PM?", "This weekend?").
- Overflow menu: "Mark session complete".

### 4.8 Rating and Review
Triggered after a session is marked complete.
- Partner header, **1–5 star rating** (required), feedback text (optional, max 300 chars), Submit.
- Success state with thank-you message; the rating updates the partner's average shown on their profile.
- One review per partner per exchange.

### 4.9 Profile
- Avatar, name, email, roll number, department, year.
- Average rating with review count; list of received reviews.
- "Skills I Teach" (green chips) and "Skills I Want to Learn" (amber chips) with Edit buttons.
- Logout button.

---

## 5. Compatibility Score Logic (Frontend Implementation)

Computed client-side for v1 using mock/local data.

```
teachMatch = |their.teach ∩ my.learn| / max(|my.learn|, 1)     // what they can give me
learnMatch = |their.learn ∩ my.teach| / max(|their.learn|, 1)  // what I can give them

score = round( (0.5 * teachMatch + 0.5 * learnMatch) * 100 )
```

- Skills are compared case-insensitively and trimmed.
- Mutual matches (both directions > 0) rank above one-sided matches.
- Exclude users with a score of 0 from the feed.
- Display the score as a percentage with the ring (e.g., "85% Match").

---

## 6. State and Data Model

### 6.1 Entities
```ts
User {
  id, name, email, rollNo, department, year,
  teachSkills: string[], learnSkills: string[],
  ratingAvg: number, ratingCount: number
}

ExchangeRequest {
  id, fromUserId, toUserId,
  status: 'pending' | 'accepted' | 'rejected',
  createdAt
}

Message { id, requestId, senderId, text, timestamp }

Review { id, requestId, reviewerId, revieweeId, stars: 1-5, comment, createdAt }
```

### 6.2 State Management
- Global store (Zustand or Redux Toolkit / Context): `auth`, `users`, `requests`, `messages`, `reviews`.
- Persist session and data locally (AsyncStorage) so the demo works offline.
- v1 uses **seeded mock data** (10–15 sample students) with a service layer (`api/`) that can later be swapped for a real backend without changing the UI.

---

## 7. Recommended Tech Stack (Frontend)

| Concern | Recommendation |
|---|---|
| Framework | **React Native with Expo** (fastest path to an Android APK) |
| Language | TypeScript |
| Navigation | React Navigation (Stack + Bottom Tabs) |
| Styling | StyleSheet with a central theme file (or NativeWind) |
| Icons | `@expo/vector-icons` / Lucide |
| State | Zustand + AsyncStorage persistence |
| Forms | React Hook Form + Zod |

*Alternative:* Flutter, if the team prefers it. The UI spec in this document applies to either.

**Suggested folder structure**
```
src/
  theme/          # colors, spacing, typography
  components/     # Button, SkillChip, MatchCard, ScoreRing, ...
  screens/        # Splash, Login, Register, Skills, Home, Requests, Chat, Rating, Profile
  navigation/     # AuthStack, MainTabs
  store/          # auth, users, requests, chat, reviews
  services/       # mock API layer
  utils/          # matching.ts, validators.ts
  data/           # seed students and skills
```

---

## 8. Using the Taste Skill for Frontend Design

Use the following skill to generate the mobile UI designs/assets for this app:

```bash
npx skills add https://github.com/leonxlnx/taste-skill --skill imagegen-frontend-mobile
```

**Suggested workflow**
1. Run the command above in the project/workspace so the skill is available to your AI coding assistant.
2. Feed this PRD (Sections 2–4) as context.
3. Generate screens one at a time in this order: Splash → Login/Register → Skills → Home → Matches → Chat → Rating → Profile.
4. Keep the design tokens from Section 2 as the single source of truth so every generated screen stays consistent.

**Master prompt template**
> Design a modern, mobile-first Android app called **SkillSwap** with a deep teal theme (primary #0D9488, accent #06B6D4), rounded 16 px cards, Inter font, and a fixed bottom navigation (Home, Matches, Chat, Profile). Green chips represent skills a student teaches; amber chips represent skills they want to learn. Screen to generate: **{screen name}** — {paste the relevant screen spec from Section 4}.

---

## 9. UX Requirements

- **Accessibility:** contrast ratio ≥ 4.5:1, touch targets ≥ 44 px, labels for icons.
- **Feedback:** every action produces a visible state (loading, toast, disabled).
- **Empty / error states** on every list screen.
- **Performance:** screen transitions under 300 ms; lists use virtualization (FlatList).
- **Responsiveness:** support 360–430 px wide phones; safe-area aware; keyboard-avoiding input in chat and forms.
- **Language:** all UI text in English.

---

## 10. Acceptance Criteria

| # | Criterion |
|---|---|
| 1 | A user can register with name, college email, roll number, department, and year. |
| 2 | Profile shows green "Teach" chips and amber "Learn" chips; both are editable. |
| 3 | Home displays matches sorted by compatibility % with a "Connect & Swap" button. |
| 4 | A request can be Pending, Accepted, or Rejected, and each status is visually distinct. |
| 5 | Chat opens **only** for Accepted partners. |
| 6 | Chat shows WhatsApp-style bubbles and sends messages in real time (locally). |
| 7 | A 1–5 star rating and feedback can be submitted after a completed session. |
| 8 | Fixed bottom nav (Home, Matches, Chat, Profile) is present on all main screens. |
| 9 | The deep teal theme is applied consistently. |
| 10 | An installable Android **APK** runs on a physical device for the demo. |

---

## 11. APK Build and Delivery

Using Expo (recommended):

```bash
# 1. Create and run the project
npx create-expo-app skillswap --template blank-typescript
cd skillswap
npx expo start            # test via Expo Go during development

# 2. Install EAS CLI and log in
npm install -g eas-cli
eas login

# 3. Configure build
eas build:configure
```

In `eas.json`, add a profile that outputs an APK (not an AAB):
```json
{
  "build": {
    "preview": {
      "android": { "buildType": "apk" }
    }
  }
}
```

```bash
# 4. Build the APK
eas build -p android --profile preview
```

- EAS returns a download link; install the APK on the demo phone (enable "Install unknown apps").
- Set `android.package` in `app.json` (e.g., `com.college.skillswap`), plus the app icon and splash.
- **Demo tip:** seed mock data so the app works without internet during the review, and pre-create two demo accounts to show a full swap → accept → chat → rate flow.

---

## 12. Milestones

| Phase | Deliverable |
|---|---|
| 1 | Design system + all screen designs (via taste skill) |
| 2 | Auth, skill inventory, profile |
| 3 | Matching feed and score logic |
| 4 | Request system and chat |
| 5 | Ratings, polish, empty/error states |
| 6 | APK build, device testing, demo script |

---

## 13. Future Enhancements
- Real backend (Firebase/Supabase) with live chat and push notifications.
- College email OTP verification.
- Session scheduling calendar and reminders.
- Badges and leaderboards for top mentors.
- Video call integration.
