# MEDITOUCH — Complete App Architecture & Design Reference

---

## Table of Contents

1. [App Overview](#1-app-overview)
2. [Tech Stack & Packages](#2-tech-stack--packages)
3. [App Entry Flow](#3-app-entry-flow)
4. [Navigation Structure](#4-navigation-structure)
5. [Patient Screens (Detailed)](#5-patient-screens-detailed)
6. [Doctor/Admin Screens (Detailed)](#6-doctoradmin-screens-detailed)
7. [Shared Screens](#7-shared-screens)
8. [Custom Widgets](#8-custom-widgets)
9. [Current Theme & Color Palette](#9-current-theme--color-palette)
10. [Data Models](#10-data-models)
11. [State Management (Riverpod Providers)](#11-state-management-riverpod-providers)
12. [Repositories (Data Layer)](#12-repositories-data-layer)
13. [Services](#13-services)
14. [Firestore Database Structure](#14-firestore-database-structure)
15. [Key User Flows](#15-key-user-flows)
16. [File Structure](#16-file-structure)

---

## 1. App Overview

**MEDITOUCH** is a Flutter health management app with two user roles:

- **Patient**: Track medicines, book appointments, log vitals/mood/hydration, chat with doctors, check symptoms
- **Doctor**: Manage appointments (accept/decline/reschedule), chat with patients, write prescriptions, view patient records

**Tagline:** "Your Digital Health Guardian"

---

## 2. Tech Stack & Packages

| Category | Package | Purpose |
|----------|---------|---------|
| State Management | `flutter_riverpod ^2.6.1` | All app state via StateNotifier + StreamProviders |
| Backend | `firebase_core ^3.12.1` | Firebase initialization |
| Database | `cloud_firestore ^5.6.5` | Real-time Firestore database |
| Auth | `firebase_auth ^5.5.1` | Email/password authentication |
| Push Notifications | `firebase_messaging ^15.2.10` | FCM cloud messaging |
| Local Notifications | `flutter_local_notifications ^21.0.0-dev.2` | Alarm-style medicine/appointment reminders |
| Timezone | `timezone ^0.11.0` | Schedule notifications in correct timezone |
| Typography | `google_fonts ^6.2.1` | Poppins (headings) + Inter (body) |
| Animations | `lottie ^3.2.1`, `animations ^2.0.11` | Lottie files + Flutter animations |
| Progress UI | `percent_indicator ^4.2.4` | Circular/linear progress indicators |
| Date Formatting | `intl ^0.19.0` | Date/time formatting |
| Local Storage | `shared_preferences ^2.3.4` | Key-value persistence |
| UUIDs | `uuid ^4.5.1` | Unique ID generation |
| App Icons | `flutter_launcher_icons ^0.14.3` | Platform icon generation (dev dependency) |

---

## 3. App Entry Flow

```
App Launch
  └─ SplashScreen (3s animated gradient background + pulsing health icon + "MEDITOUCH" fadeIn)
      └─ AuthGate (watches Firebase auth stream)
          ├─ NOT authenticated → AuthScreen (Login / Sign Up)
          └─ Authenticated → AppLoader (loads Firestore data)
              ├─ Onboarding NOT complete → OnboardingScreen (4-step form)
              └─ Onboarding complete
                  ├─ Role = "user" (patient) → PatientShell (5-tab BottomNavigationBar)
                  └─ Role = "doctor" → AdminShell (6-tab BottomNavigationBar)
```

**Services initialized at startup:**
- `NotificationService().init()` — local notification channels
- `FcmService().init()` — FCM token registration
- `PushNotificationListener().startListening()` — real-time Firestore notification listener

---

## 4. Navigation Structure

### Patient Bottom Navigation Bar (5 tabs)

| Tab Index | Icon | Label | Screen | File |
|-----------|------|-------|--------|------|
| 0 | Home icon | Home | `HomeScreen` | `home_screen.dart` |
| 1 | Pill icon | Medicines | `MedicinesScreen` | `medicines_screen.dart` |
| 2 | Calendar icon | Appointments | `AppointmentsScreen` | `appointments_screen.dart` |
| 3 | Person icon | Profile | `ProfileScreen` | `profile_screen.dart` |
| 4 | Search/Health icon | Symptoms | `SymptomCheckerScreen` | `symptom_checker_screen.dart` |

**State:** `currentTabProvider` (StateProvider<int>) controls the active tab.

### Doctor Bottom Navigation Bar (6 tabs)

| Tab Index | Icon | Label | Screen | File |
|-----------|------|-------|--------|------|
| 0 | Dashboard icon | Dashboard | `AdminDashboardScreen` | `admin/admin_dashboard_screen.dart` |
| 1 | Calendar icon | Appointments | `AdminAppointmentsScreen` | `admin/admin_appointments_screen.dart` |
| 2 | Chat icon | Chat | `AdminChatScreen` | `admin/admin_chat_screen.dart` |
| 3 | Prescription icon | Prescriptions | `AdminPrescriptionsScreen` | `admin/admin_prescriptions_screen.dart` |
| 4 | People icon | Patients | `AdminPatientsScreen` | `admin/admin_patients_screen.dart` |
| 5 | Person icon | Profile | `AdminDoctorProfileScreen` | `admin/admin_doctor_profile_screen.dart` |

**State:** `adminTabProvider` (StateProvider<int>) controls the active tab.

---

## 5. Patient Screens (Detailed)

### 5.1 Home Screen (`home_screen.dart`)

**Background:** `NebulaBackground` (animated gradient + floating orbs)
**Layout:** `Scaffold` (transparent) → `SafeArea` → `SingleChildScrollView`

| Section | UI Elements | Interactions |
|---------|------------|--------------|
| **Header** | Avatar circle + "Good morning, [Name]" + date text + notification bell icon with red unread-count badge | Bell tap → `PatientNotificationsScreen` |
| **Adherence Streak** | Badge showing streak count (only if > 0) | Display only |
| **Medicine Progress** | `GlassCard` with circular progress indicator showing taken_doses / total_doses percentage | Display only |
| **Hydration** | Water glass counter with + / - buttons, shows glasses / goal | + adds glass, - removes glass |
| **Health Tip** | Card with rotating daily health tips | Display only |
| **Vitals Snapshot** | Row of 3 mini cards: Heart Rate, Blood Pressure, Blood Sugar — each showing latest value | Display only |
| **Next Up** | Card showing the next medicine to take (name, dosage, time) | Display only |
| **Appointments** | Card showing next upcoming appointment (doctor name, date, status) | Tap → appointment details |
| **Daily Check-In** | Mood section with "Log Mood" gradient button | Tap → mood selector (1–5 scale with emoji icons) |

**Visual style:**
- Section headers: accent-colored vertical bar (4px) + uppercase label text
- All cards use `GlassCard` (semi-transparent white background with border glow)
- Circular progress: percentage text overlay in center

---

### 5.2 Medicines Screen (`medicines_screen.dart`)

**Layout:** `Scaffold` → list view with search + filters

| Element | Description | Interaction |
|---------|------------|-------------|
| **AppBar** | Title "Medicines" | — |
| **Search Bar** | Text field to filter medicines by name | Filters list in real-time |
| **Filter Chips** | Row: All, Active, Completed, Today | Tap to filter medicines list |
| **Medicine List** | Scrollable list of medicine cards | — |
| **Each Medicine Card** | Accent bar (colored left border) + medicine name + dosage + form + reminder time chips + Take/Mark Taken buttons | Tap → edit medicine; Take button → marks dose as taken |
| **FAB** (Floating Action Button) | "+" icon | Tap → navigates to `AddMedicineScreen` |

---

### 5.3 Add/Edit Medicine Screen (`add_medicine_screen.dart`)

**Layout:** Full-screen form

| Form Field | Type | Details |
|------------|------|---------|
| Medicine Name | Text input | Required |
| Dosage | Text input | Required (e.g., "500mg") |
| Form | Dropdown | Options: Tablet, Capsule, Syrup, Injection, Other |
| Frequency | Dropdown | Options: Once a day, Twice a day, Three times a day, etc. |
| With Food | Toggle switch | Boolean |
| Notes | Text area | Optional |
| Reminder Times | Chip list + "+" button | Each chip shows time (e.g., "8:00 AM"); tap chip to remove; tap "+" to open time picker |
| **Save Button** | Gradient button | Creates/updates medicine + schedules local notifications |

---

### 5.4 Appointments Screen (`appointments_screen.dart`)

**Layout:** Scaffold with segmented control + list

| Element | Description | Interaction |
|---------|------------|-------------|
| **Segmented Control** | Two segments: "Upcoming" / "Past" | Toggles list filter |
| **Search Bar** | Filter by doctor name | Real-time filtering |
| **Appointment List** | Real-time stream (updates instantly on status changes) | — |
| **Each Appointment Card** | Doctor avatar + name + specialty icon (color-coded by specialty) + date/time + status badge (pending=orange, accepted=green, declined=red, cancelled=gray) + location | — |
| **Action Buttons** (per status): | | |
| — Pending | "Cancel" button | Cancels appointment |
| — Accepted | "Chat" button | Opens `PatientChatDetailScreen` |
| — Declined/Cancelled | No actions | Display only |
| **FAB** | "+" icon | Opens new appointment booking form |

**Status badge colors:**
- Pending → Orange
- Accepted → Green
- Declined → Red
- Cancelled → Gray

---

### 5.5 Profile Screen (`profile_screen.dart`)

**Layout:** Scaffold → ScrollView with editable fields

| Section | UI Elements | Interaction |
|---------|------------|-------------|
| **Avatar** | Large circular avatar with gradient border + glow | Tap → opens `AvatarPicker` bottom sheet |
| **Name** | Editable text field | Direct edit |
| **Age, Gender** | Text field + Dropdown | Direct edit |
| **Blood Group** | Dropdown (A+, A-, B+, B-, O+, O-, AB+, AB-) + color badge | Select from dropdown |
| **Phone, Email** | Text fields | Direct edit |
| **Height, Weight** | Text fields (numeric) → auto-calculates BMI | Edit triggers BMI recalc |
| **BMI Card** | Color-coded card (green=normal, yellow=overweight, orange=obese, blue=underweight) showing BMI value + category | Display only |
| **Emergency Contact** | Name + phone fields | Direct edit |
| **Health Conditions** | Chip list (multi-select from predefined + custom input) | Tap to toggle; type to add custom |
| **Allergies** | Chip list (multi-select from predefined + custom input) | Tap to toggle; type to add custom |
| **Save Button** | Gradient button at bottom | Saves profile to Firestore |
| **Logout Button** | Red text button | Signs out, clears FCM token, returns to AuthScreen |

---

### 5.6 Symptom Checker Screen (`symptom_checker_screen.dart`)

**Layout:** Scaffold → Column with chips + results

| Element | Description | Interaction |
|---------|------------|-------------|
| **Disclaimer Card** | Info icon + "This is for informational purposes only. Consult a doctor for severe symptoms." | Display only |
| **Symptom Chips** (8 total) | Fever, Headache, Cough, Sore Throat, Stomach Ache, Nausea, Allergies, Body Ache | Tap to toggle on/off (multi-select) |
| **Suggested Medicines** | Dynamically updates based on selected symptoms; shows OTC medicine cards with name + dosing info | Display only |

**Symptom → OTC mapping:** Each symptom maps to a predefined list of over-the-counter medicines with dosage suggestions.

---

### 5.7 Patient Chat Screen (`patient_chat_screen.dart`)

**Two sub-screens:**

**Chat Room List:**
| Element | Description | Interaction |
|---------|------------|-------------|
| **Room Tiles** | Real-time stream; each shows: doctor initials in gradient circle + doctor name + last message preview + relative timestamp | Tap → opens ChatDetailScreen |

**Chat Detail Screen:**
| Element | Description | Interaction |
|---------|------------|-------------|
| **Message List** | Real-time Firestore stream ordered by timestamp; messages styled differently for sent vs received | Auto-scrolls to latest |
| **Text Input** | TextField + Send icon button at bottom | Type message + tap send |

---

### 5.8 Patient Notifications Screen (`patient_notifications_screen.dart`)

| Element | Description | Interaction |
|---------|------------|-------------|
| **Notification List** | Real-time stream of `AdminNotification` objects | — |
| **Each Tile** | Colored icon (by type) + title + body + relative timestamp + unread red dot | Tap → marks as read |

**Notification types:** appointment status changes, new chat messages, new prescriptions

---

## 6. Doctor/Admin Screens (Detailed)

### 6.1 Admin Dashboard (`admin/admin_dashboard_screen.dart`)

| Section | UI Elements | Interaction |
|---------|------------|-------------|
| **Header** | "Good [morning/afternoon/evening], Dr. [Name]" + notification bell with unread badge | Bell → `AdminNotificationsScreen` |
| **Stats Row** | 3 cards: Pending (orange) count, Accepted (green) count, Total (blue) count | Display only |
| **Today's Appointments** | List of appointments with date = today; each shows patient name + time + status + action buttons | Accept/Decline/Reschedule buttons |
| **Pending Appointments** | Shows first 3 pending appointments with Accept/Decline/Reschedule actions | Action buttons trigger status update + patient notification |

---

### 6.2 Admin Appointments (`admin/admin_appointments_screen.dart`)

| Element | Description | Interaction |
|---------|------------|-------------|
| **Header** | Title with calendar icon | — |
| **Search Bar** | Filter by patient name | Real-time filtering |
| **Filter Chips** | All, Pending, Accepted, Declined, Cancelled | Tap to filter |
| **Appointment List** | Real-time stream from shared appointments collection | — |
| **Each Card** | Patient avatar + name + specialty icon (color-coded) + date/time + status badge + location | Tap → details modal |
| **Action Buttons (by status):** | | |
| — Pending | Accept / Decline / Reschedule | Accept → changes status + creates chat room + notifies patient |
| — Accepted | Reschedule / Cancel / Chat | Chat → opens `AdminChatDetailScreen` |
| — Declined/Cancelled | No actions | Display only |

**Modal actions:**
- **Accept:** status → 'accepted', auto-creates chat room, fires patient notification
- **Decline:** prompts for reason, status → 'declined', patient notified
- **Reschedule:** date/time picker, updates dateTime + status → 'accepted'
- **Cancel:** prompts for reason, status → 'cancelled', patient notified

---

### 6.3 Admin Chat (`admin/admin_chat_screen.dart`)

**Chat Room List:**
| Element | Description | Interaction |
|---------|------------|-------------|
| **Room Tiles** | Real-time stream; patient initials in gradient circle + patient name + last message + timestamp | Tap → `AdminChatDetailScreen` |

**Chat Detail Screen:**
| Element | Description | Interaction |
|---------|------------|-------------|
| **Messages** | Real-time Firestore stream, ordered ascending by timestamp | Auto-scrolls |
| **Input** | TextField + send button | Send message |

---

### 6.4 Admin Prescriptions (`admin/admin_prescriptions_screen.dart`)

| Element | Description | Interaction |
|---------|------------|-------------|
| **Prescription List** | Cards showing: patient name + diagnosis + medicine count + creation date | Tap → edit |
| **FAB** | "+" icon | Opens prescription editor |
| **Prescription Editor (Modal):** | | |
| — Patient selector | Search/dropdown to pick patient | Select patient |
| — Diagnosis | Text field | Type diagnosis |
| — Medicine Rows (dynamic) | Each row: name, dosage, frequency, duration, instructions + Add/Remove buttons | Add/remove medicine entries |
| — Notes | Text field | Optional notes |
| — Save Button | Gradient button | Writes to Firestore |

---

### 6.5 Admin Patients (`admin/admin_patients_screen.dart`)

| Element | Description | Interaction |
|---------|------------|-------------|
| **Search Bar** | Filter by name or username | Real-time filtering |
| **Patient Cards** | Avatar + name + username | Tap → patient detail modal |
| **Detail Modal** | Read-only patient profile: name, age, gender, blood group, height, weight, BMI, health conditions, allergies, emergency contacts, previous appointments, current medications | Display only |

---

### 6.6 Admin Doctor Profile (`admin/admin_doctor_profile_screen.dart`)

| Section | UI Elements | Interaction |
|---------|------------|-------------|
| **Avatar** | Large circle with gradient border | Tap → `AvatarPicker` |
| **Full Name** | Editable text field | Direct edit |
| **Username** | Read-only display (set at signup) | — |
| **Specialty** | Dropdown or text field | Edit |
| **Phone, Email** | Text fields | Edit |
| **Bio** | Text area | Edit |
| **Availability** | Edit modal with time pickers per day of week | Set start/end times + slot duration per day |
| **Save Button** | Gradient button | Updates Firestore |
| **Logout Button** | Red button | Signs out + clears FCM token |

---

### 6.7 Admin Notifications (`admin/admin_notifications_screen.dart`)

| Element | Description | Interaction |
|---------|------------|-------------|
| **AppBar action** | "Mark all as read" button | Marks all notifications read |
| **Notification List** | Real-time stream of doctor's notifications | — |
| **Each Tile** | Colored icon (appointment=blue, chat=green, prescription=purple) + title + body + relative timestamp + unread dot | Tap → marks as read |

---

## 7. Shared Screens

### 7.1 Auth Screen (`auth_screen.dart`)

**Dual mode toggle:** Login ↔ Sign Up

**Login Mode:**
| Field | Type |
|-------|------|
| Email | Text input |
| Password | Password input |
| "Forgot Password?" | Text button → sends reset email |
| "Login" | Gradient button |
| "Don't have an account? Sign Up" | Toggle link |

**Sign Up Mode:**
| Field / Step | Type |
|-------------|------|
| Full Name | Text input |
| Email | Text input |
| Password | Password input |
| Confirm Password | Password input |
| Role | Toggle: Patient / Doctor |
| Avatar | Avatar picker (theme + variant selection) |
| Username | Text input (checks availability against 'usernames' collection) |
| "Sign Up" | Gradient button |

**Sign Up writes (batch):**
1. Create Firebase Auth account
2. Reserve username in 'usernames' collection
3. Create user profile document
4. If doctor: create doctorProfile document

---

### 7.2 Onboarding Screen (`onboarding_screen.dart`) — Patients Only

**4-step multi-page form with animated progress bar:**

| Step | Fields | UI Notes |
|------|--------|----------|
| **1. Personal Info** | Name, age, phone, email, gender (dropdown), blood group (dropdown) | Step icon + label in AppBar |
| **2. Body & Emergency** | Height, weight, emergency contact name + phone | Skip button appears |
| **3. Health Conditions** | Multi-select from predefined list (kCommonConditions) + custom text input to add more | Chips toggle on/off |
| **4. Allergies** | Multi-select from predefined list (kCommonAllergies) + custom text input | Chips toggle on/off |

**Navigation:** Back button (steps 1+), Continue/Skip buttons, neon progress bar animates per step, accent color changes per step.

---

### 7.3 Splash Screen (`splash_screen.dart`)

- Animated gradient background (blue → black → pink shifting)
- Pulsing gradient circle with health/medical icon in center
- Fade-in app name "MEDITOUCH" + tagline text
- 3-second delay → navigate to AuthGate

---

## 8. Custom Widgets

### `GlassCard` (`widgets/glass_card.dart`)
Glassmorphic card container. Semi-transparent white background (0x28FFFFFF) with subtle border + rounded corners. Used on almost every card in the app.
- Props: `child`, `margin`, `padding`, `borderRadius`, `borderColor`

### `GradientButton` (`widgets/gradient_button.dart`)
Animated button with accent gradient background + glow effect on tap. Used for all primary actions (Save, Login, Continue, etc.).
- Props: `label`, `onPressed`, `icon`, `height`
- Animation: glow shadow appears on press

### `NebulaBackground` (`widgets/nebula_background.dart`)
Animated full-screen background used on every major screen. Features:
- 3 floating translucent circles (Electric Blue, Radiant Pink, Neon Green) that drift slowly across the screen
- Creates a "nebula" or "aurora" effect behind content

### `UserAvatar` (`widgets/user_avatar.dart`)
Circular avatar with gradient border and optional ambient glow. Loads DiceBear API image or shows initial letter fallback.
- Props: `imageUrl`, `name`, `radius`, `showGlow`, `borderGradient`

### `AccentBar` (`widgets/accent_bar.dart`)
Thin vertical colored bar (4px wide) used on the left side of list items/cards for visual accent.
- Props: `color`, `height`, `width`

### `AvatarPicker` (`widgets/avatar_picker.dart`)
Bottom sheet modal for choosing avatar. Shows 8 DiceBear themes (Adventurer, Pixel Art, Lorelei, etc.) with 6 variants each. Returns selected URL.

---

## 9. Current Theme & Color Palette

**File:** `lib/theme/app_theme.dart`

### Colors

| Name | Hex | Usage |
|------|-----|-------|
| `bgPrimary` | `#181A20` | Charcoal Black — main background |
| `bgSecondary` | `#23243A` | Deep Slate — card/section backgrounds |
| `electricBlue` | `#00B4FF` | Primary accent — buttons, selected icons, links |
| `neonGreen` | `#00FFB0` | Success/health — streak badges, positive indicators |
| `vividOrange` | `#FF8C42` | Warning — pending status, alerts |
| `radiantPink` | `#FF4F8B` | Accent — secondary gradients, highlights |
| `textPrimary` | `#FFFFFF` | White — headings, primary text |
| `textSecondary` | `#B0B3C6` | Light Gray — body text, labels |
| `glassWhite` | `#14FFFFFF` | ~8% opacity white — glass card fill |
| `glassBorder` | `#30FFFFFF` | ~19% opacity white — glass card borders |

### Gradients

| Name | Colors | Usage |
|------|--------|-------|
| `accentGradient` | electricBlue → radiantPink | Primary buttons, progress indicators |
| `greenBlueGradient` | neonGreen → electricBlue | Success states, health indicators |
| `orangePinkGradient` | vividOrange → radiantPink | Warning states, alerts |

### Typography

| Context | Font | Weight |
|---------|------|--------|
| Headings, titles, app name | **Poppins** | Bold / SemiBold |
| Body text, labels, inputs | **Inter** | Regular / Medium |

### Material Theme Settings

- **Material3:** Enabled
- **AppBarTheme:** Transparent background, no elevation, white title text
- **CardTheme:** Glassmorphic (`glassWhite` bg + `glassBorder` border + 20px border radius)
- **BottomNavigationBar:** Fixed type, `electricBlue` selected color, `textSecondary` unselected
- **FAB:** Rounded 28px border, no elevation
- **InputDecoration:** Glassmorphic fill (`glassWhite`), 14px border radius
- **ElevatedButton:** `electricBlue` background, 16px border radius
- **Chips:** Blue tint background (`0x3300B4FF`), custom border

### Helper: `glow(Color, {blur, spread})`
Returns `BoxShadow` list for ambient glow effects around cards/buttons.

---

## 10. Data Models

**File:** `lib/models/models.dart`

### UserProfile
```
id, name, username, uniqueId
age, gender, phone, email, bloodGroup
emergencyContactName, emergencyContactPhone
healthConditions: List<String>
allergies: List<String>
height, weight
onboardingComplete: bool
role: String ('user' | 'doctor')
profilePicture: String (DiceBear URL)
Computed: bmi, bmiCategory, isDoctor
```

### Medicine
```
id, name, dosage
form: String ('Tablet' | 'Capsule' | 'Syrup' | 'Injection' | 'Other')
reminderTimes: List<String> (e.g. ['8:00 AM', '8:00 PM'])
frequency: String ('Once a day' | 'Twice a day' | 'Three times a day' | etc.)
withFood: bool
notes: String
isCompleted: bool, isReminderOn: bool
takenTimes: List<String> (tracks when doses were marked as taken)
Computed: takenCount, totalDoses
```

### Appointment
```
id, doctorName, specialty, dateTime, location
status: String ('pending' | 'accepted' | 'declined' | 'confirmed' | 'cancelled')
notes, patientId, patientName, doctorId
cancelReason: String?
Computed: isUpcoming, isPast, isPending, isAccepted, isDeclined, isCancelled
```

### DailyCheckIn
```
id, date, mood: int (1–5), note: String
```

### WaterIntake
```
date, glassCount: int, goal: int (default 8)
Computed: percentage
```

### VitalRecord
```
id, type: String ('bp' | 'heartRate' | 'weight' | 'bloodSugar')
value: double, value2: double? (for BP diastolic)
recordedAt: DateTime, unit: String ('mmHg' | 'bpm' | 'kg' | 'mg/dL')
```

### ChatMessage
```
id, senderId, text, timestamp: DateTime
```

### ChatRoom
```
id, doctorId, patientId, doctorName, patientName
lastMessage: String, lastMessageTime: DateTime
```

### Prescription
```
id, doctorId, patientId, patientName, doctorName
medicines: List<PrescriptionItem>
diagnosis, notes, createdAt: DateTime
```

### PrescriptionItem
```
name, dosage, frequency, duration, instructions
```

### DoctorProfile
```
id, name, username, specialty
phone, email, bio, profilePicture
availability: List<DoctorAvailability>
```

### DoctorAvailability
```
dayOfWeek: String, startTime: String, endTime: String, slotDurationMinutes: int
```

### AdminNotification
```
id, type: String ('appointment' | 'chat' | 'prescription')
title, body, timestamp: DateTime
isRead: bool, referenceId: String
```

### Constants
- `kCommonConditions` — predefined health conditions list
- `kCommonAllergies` — predefined allergies list
- `kBloodGroups` — A+, A-, B+, B-, O+, O-, AB+, AB-
- `kSpecialties` — list of medical specialties

---

## 11. State Management (Riverpod Providers)

### Patient Providers (`lib/providers/providers.dart`)

| Provider | Type | Purpose |
|----------|------|---------|
| `authStateProvider` | StreamProvider | Firebase auth state stream |
| `medicinesRepoProvider` | Provider | Medicines repository instance |
| `appointmentsRepoProvider` | Provider | Appointments repository instance |
| `profileRepoProvider` | Provider | Profile repository instance |
| `checkInRepoProvider` | Provider | Check-in repository instance |
| `medicinesProvider` | StateNotifierProvider | List\<Medicine\> — add, update, delete, markTimeTaken, markAllTaken; adherenceStreak computed |
| `appointmentsProvider` | StateNotifierProvider | List\<Appointment\> — add, update, delete; upcoming/past/nextUpcoming computed |
| `profileProvider` | StateNotifierProvider | UserProfile — load, update |
| `checkInProvider` | StateNotifierProvider | DailyCheckIn? — today's check-in or null |
| `waterIntakeProvider` | StateNotifierProvider | WaterIntake — addGlass, removeGlass, setGoal |
| `vitalsProvider` | StateNotifierProvider | List\<VitalRecord\> — add, getByType, latestOfType |
| `patientAppointmentsStreamProvider` | StreamProvider | Real-time patient appointments |
| `patientNotificationsStreamProvider` | StreamProvider | Real-time patient notifications |
| `patientChatRoomsStreamProvider` | StreamProvider | Real-time patient chat rooms |
| `currentTabProvider` | StateProvider\<int\> | Bottom nav tab index |

### Doctor Providers (`lib/providers/admin_providers.dart`)

| Provider | Type | Purpose |
|----------|------|---------|
| `adminAppointmentsRepoProvider` | Provider | Admin appointments repository |
| `chatRepoProvider` | Provider | Chat repository |
| `prescriptionsRepoProvider` | Provider | Prescriptions repository |
| `doctorProfileRepoProvider` | Provider | Doctor profile repository |
| `adminNotificationsRepoProvider` | Provider | Admin notifications repository |
| `adminAppointmentsProvider` | StateNotifierProvider | List\<Appointment\> — accept, decline, reschedule, cancel; pending/upcoming/past computed |
| `prescriptionsProvider` | StateNotifierProvider | List\<Prescription\> — add, update, delete; getByPatient |
| `doctorProfileProvider` | StateNotifierProvider | DoctorProfile? — load, save |
| `adminNotificationsProvider` | StateNotifierProvider | List\<AdminNotification\> — add, markAsRead, markAllAsRead; unreadCount computed |
| `adminAppointmentsStreamProvider` | StreamProvider | Real-time doctor appointments |
| `chatRoomsStreamProvider` | StreamProvider | Real-time doctor chat rooms |
| `chatMessagesStreamProvider` | StreamProvider.family | Real-time messages for a chat room (takes chatRoomId) |
| `adminNotificationsStreamProvider` | StreamProvider | Real-time doctor notifications |
| `adminTabProvider` | StateProvider\<int\> | Admin bottom tab index |

---

## 12. Repositories (Data Layer)

| Repository | File | Key Methods |
|-----------|------|-------------|
| **MedicinesRepository** | `medicines_repository.dart` | loadAll, getAll, getById, add, update, delete, markTimeTaken, markAllTaken |
| **AppointmentsRepository** | `appointments_repository.dart` | loadAll, getAll, getUpcoming, getPast, getNextUpcoming, getById, add (writes to personal + shared collection + creates admin notification), update, delete, watchAppointments (stream) |
| **ProfileRepository** | `profile_repository.dart` | load, get, update (stored as 'default_user' doc) |
| **CheckInRepository** | `checkin_repository.dart` | loadAll, getAll, getToday, saveMood |
| **AdminAppointmentsRepository** | `admin_appointments_repository.dart` | loadAll (from shared collection), getAll, getPending, getUpcoming, getPast, getByStatus, getByPatientId, acceptAppointment (+ create chat room + notify patient), declineAppointment, rescheduleAppointment, cancelAppointment, watchAppointments (stream) |
| **ChatRepository** | `chat_repository.dart` | getOrCreateChatRoom, getDoctorChatRooms, watchDoctorChatRooms, watchPatientChatRooms, sendMessage (+ update lastMessage), watchMessages (stream) |
| **PrescriptionsRepository** | `prescriptions_repository.dart` | loadAll, getAll, getByPatientId, add, update, delete |
| **DoctorProfileRepository** | `doctor_profile_repository.dart` | load, get, save (top-level 'doctorProfiles' collection) |
| **AdminNotificationsRepository** | `admin_notifications_repository.dart` | loadAll, getAll, unreadCount, add, markAsRead, markAllAsRead, watchNotifications (stream) |

---

## 13. Services

### AuthService (`lib/services/auth_service.dart`)
- `signUp(email, password)` → creates Firebase Auth account
- `signIn(email, password)` → authenticates
- `signOut()` → clears FCM token, stops push listeners, signs out
- `resetPassword(email)` → sends password reset email

### FirestoreService (`lib/services/firestore_service.dart`)
- Singleton providing Firestore collection references
- **User-scoped** (under `users/{uid}/`): medicines, appointments, profile, checkIns, adminNotifications
- **Shared top-level**: sharedAppointments, chatRooms, prescriptions, doctorProfiles, usernames
- **Helpers**: `userProfileCollection(userId)`, `userMedicinesCollection(userId)` — for cross-user access

### NotificationService (`lib/services/notification_service.dart`)
- `init()` — initializes Android + iOS notification channels
- `requestPermissions()` — requests notification permissions
- `scheduleMedicineNotification(medicine, time)` — alarm-style exact notifications; parses time strings; supports snooze (re-fires after 10 min)
- `scheduleAppointmentNotification(appointment)` — pre-appointment reminders
- `cancelMedicineNotifications(medicineId)`, `cancelAppointmentNotification(appointmentId)`

### FcmService (`lib/services/fcm_service.dart`)
- `init()` — requests FCM permission, saves token to Firestore, listens for foreground messages
- `saveTokenToFirestore()` — writes FCM token to user document
- Listens to `onTokenRefresh` for automatic token updates
- `firebaseMessagingBackgroundHandler()` — top-level background handler

### PushNotificationListener (`lib/services/push_notification_listener.dart`)
- Custom Firestore-based push notification system (works without Cloud Functions)
- `startListening()` — streams user's 'adminNotifications' subcollection; on new doc → shows local push notification
- Pre-loads existing notification IDs to avoid duplicates on app restart
- `stopListening()` — cancels streams (called on sign-out)

---

## 14. Firestore Database Structure

```
users/
  └─ {uid}/
      ├─ profile/
      │   └─ default_user          → UserProfile document
      ├─ medicines/
      │   └─ {medicineId}          → Medicine document
      ├─ appointments/
      │   └─ {appointmentId}       → Appointment document (patient's personal copy)
      ├─ checkIns/
      │   └─ {checkInId}           → DailyCheckIn document
      └─ adminNotifications/
          └─ {notificationId}      → AdminNotification document

(Top-level shared collections)
appointments/
  └─ {appointmentId}               → Appointment document (shared, doctor queries this)

chatRooms/
  └─ {chatRoomId}/
      └─ messages/
          └─ {messageId}           → ChatMessage document

prescriptions/
  └─ {prescriptionId}             → Prescription document

doctorProfiles/
  └─ {doctorUid}                  → DoctorProfile document

usernames/
  └─ {username}                   → { uid, name } (for uniqueness check)
```

---

## 15. Key User Flows

### Medicine Reminder Flow
1. Patient adds medicine (name, dosage, form, frequency, reminder times)
2. App schedules alarm-style local notifications for each reminder time
3. Notification fires → patient can "Take" or "Snooze" (10 min delay)
4. Patient marks individual doses or "mark all taken" for the day
5. Adherence streak is computed from consecutive days of full compliance
6. All data persists in Firestore under user's medicines subcollection

### Appointment Booking Flow
1. Patient creates appointment (selects doctor, datetime, reason)
2. App writes to **both** patient's personal collection AND shared top-level collection
3. App creates `AdminNotification` for the doctor (type: 'appointment')
4. Doctor sees pending appointment in dashboard (real-time stream)
5. Doctor **accepts** → status = 'accepted', chat room auto-created, patient notified
6. Doctor **declines** → prompted for reason, status = 'declined', patient notified
7. Doctor **reschedules** → date/time picker, updates datetime, patient notified
8. Patient sees status changes instantly (real-time stream)

### Doctor-Patient Chat Flow
1. Chat room created automatically when doctor accepts an appointment
2. Both sides see room in their Chat tab
3. Messages stored in `chatRooms/{roomId}/messages/` with senderId + timestamp
4. Real-time Firestore stream keeps both sides synchronized
5. New message notification pushed to recipient via `AdminNotification`

### Prescription Flow
1. Doctor opens prescription editor, selects patient
2. Enters diagnosis + dynamic list of medicines (name, dosage, frequency, duration, instructions)
3. Saves to top-level `prescriptions` collection
4. Patient receives notification about new prescription

---

## 16. File Structure

```
lib/
├── main.dart                              # App entry, routing, SplashScreen, AuthGate, shells
├── firebase_options.dart                  # Firebase config (auto-generated)
│
├── models/
│   └── models.dart                        # All data models + constants
│
├── providers/
│   ├── providers.dart                     # Patient-side Riverpod providers
│   └── admin_providers.dart               # Doctor-side Riverpod providers
│
├── repositories/
│   ├── medicines_repository.dart          # Medicine CRUD
│   ├── appointments_repository.dart       # Patient appointment CRUD + streams
│   ├── admin_appointments_repository.dart # Doctor appointment management
│   ├── chat_repository.dart               # Chat rooms + messages
│   ├── prescriptions_repository.dart      # Prescription CRUD
│   ├── doctor_profile_repository.dart     # Doctor profile CRUD
│   └── admin_notifications_repository.dart# Notification CRUD + streams
│
├── services/
│   ├── auth_service.dart                  # Firebase Auth wrapper
│   ├── firestore_service.dart             # Firestore collection references
│   ├── notification_service.dart          # Local notifications (medicine/appointment reminders)
│   ├── fcm_service.dart                   # Firebase Cloud Messaging
│   └── push_notification_listener.dart    # Firestore-based push notification listener
│
├── screens/
│   ├── home_screen.dart                   # Patient dashboard
│   ├── medicines_screen.dart              # Medicine list + filters
│   ├── add_medicine_screen.dart           # Add/edit medicine form
│   ├── appointments_screen.dart           # Patient appointments list
│   ├── profile_screen.dart                # Patient profile editor
│   ├── symptom_checker_screen.dart        # OTC symptom checker
│   ├── auth_screen.dart                   # Login / Sign Up
│   ├── onboarding_screen.dart             # 4-step patient onboarding
│   ├── splash_screen.dart                 # Animated splash
│   ├── patient_chat_screen.dart           # Patient chat rooms + detail
│   ├── patient_notifications_screen.dart  # Patient notifications
│   └── admin/
│       ├── admin_dashboard_screen.dart    # Doctor dashboard
│       ├── admin_appointments_screen.dart # Doctor appointment management
│       ├── admin_chat_screen.dart         # Doctor chat rooms + detail
│       ├── admin_prescriptions_screen.dart# Prescription management
│       ├── admin_patients_screen.dart     # Patient list + details
│       ├── admin_doctor_profile_screen.dart# Doctor profile editor
│       └── admin_notifications_screen.dart# Doctor notifications
│
├── widgets/
│   ├── glass_card.dart                    # Glassmorphic card
│   ├── gradient_button.dart               # Animated gradient button
│   ├── nebula_background.dart             # Animated floating orbs background
│   ├── user_avatar.dart                   # Avatar with gradient border
│   ├── accent_bar.dart                    # Colored vertical accent bar
│   └── avatar_picker.dart                 # DiceBear avatar selection sheet
│
└── theme/
    └── app_theme.dart                     # Colors, gradients, typography, Material theme

assets/
├── noise.png                              # Texture overlay
└── app_logo.png                           # App icon source image
```

---

> **To redesign the theme:** Focus on `lib/theme/app_theme.dart` (color palette, gradients, typography), `lib/widgets/` (glass_card, gradient_button, nebula_background), and the per-screen styling in each screen file. All screens reference `AppTheme` constants for colors and use the custom widgets above for consistent visual treatment.

---

## 17. Design Specification — Theme & Visual Identity

> **Hand this section to any designer or AI tool to produce a visually stunning, modern, and unique health app UI.**

### Overall Visual Style

| Attribute | Description |
|-----------|-------------|
| **Theme** | Futuristic, glassmorphic, and neon health-tech |
| **Mood** | Energetic, trustworthy, and innovative |
| **Inspiration** | Sci-fi dashboards, cyberpunk, aurora borealis, modern health apps |
| **Contrast** | Dark backgrounds with vibrant neon accents (electric blue, radiant pink, neon green, vivid orange) |
| **Depth** | Glassmorphism (blurred, semi-transparent cards), glowing gradients, floating elements for depth and immersion |
| **Typography** | Modern, geometric sans-serif fonts (Poppins for headings, Inter for body) |

### Color Palette

| Role | Color | Hex |
|------|-------|-----|
| Background | Deep charcoal black | `#181A20` |
| Cards/Sections | Glassmorphic white | `#14FFFFFF` |
| Card borders | Glowing borders | `#30FFFFFF` |
| Primary Accent | Electric Blue | `#00B4FF` |
| Secondary Accent | Radiant Pink | `#FF4F8B` |
| Success | Neon Green | `#00FFB0` |
| Warning | Vivid Orange | `#FF8C42` |
| Heading Text | Pure white | `#FFFFFF` |
| Body Text | Light gray | `#B0B3C6` |

**Gradients:**
- **Primary:** Electric Blue → Radiant Pink
- **Success:** Neon Green → Electric Blue
- **Warning:** Vivid Orange → Radiant Pink

Background uses subtle animated gradients shifting between deep blue, black, pink, and green.

### Loading/Splash Screen

Design the most impressive loading screen possible:

- **Background:** Animated, shifting gradient nebula (deep blue, black, pink, green) with floating, glowing orbs drifting slowly
- **Centerpiece:** Large, pulsing glassmorphic circle with a glowing health/medical icon (heart, cross, or custom logo) — icon has neon glow (electric blue or radiant pink)
- **App Name:** "MEDITOUCH" in bold Poppins, white with a subtle neon blue glow, fades in below the icon
- **Tagline:** "Your Digital Health Guardian" in Inter, radiant pink, animates in after the app name
- **Progress Animation:** Circular progress indicator around the icon using the accent gradient; optionally add a subtle shimmer or particle effect
- **Duration:** 3 seconds, then smooth transition to AuthGate

### Screen & Widget Design

| Element | Style/Effect |
|---------|-------------|
| **Cards** | Glassmorphic with blurred backgrounds, glowing borders, soft drop shadows. Vertical accent bars in neon colors for section headers |
| **Buttons** | Gradient-filled with animated glow on tap. Rounded corners, bold text, subtle shadow |
| **Avatars** | Circular with animated gradient borders and ambient glow. DiceBear or custom avatars with a sci-fi/anime twist |
| **Navigation Bars** | Semi-transparent with neon accent for selected tab. Line-based modern icons filled with accent gradients |
| **Progress Indicators** | Circular and linear, always using the accent gradient. Centered percentage text with bold, glowing font |
| **Input Fields** | Glassmorphic fill, rounded corners, glowing border on focus |
| **Chips & Badges** | Neon-tinted backgrounds, glowing border, bold text |

### Animations & Microinteractions

- **Transitions:** Fade, scale, and slide transitions between screens. Cards and buttons have a slight "pop" or glow on interaction
- **Lottie Animations:** Use for health tips, mood logging, and empty states
- **Notification Bell:** Animated shake and glow when new notifications arrive

### Accessibility

- Ensure high contrast between text and backgrounds
- Use colorblind-friendly accent colors
- All interactive elements should have clear focus and tap states

### Typography

| Context | Font | Style |
|---------|------|-------|
| Headings | Poppins | Bold, all-caps or title case, white with neon glow |
| Body | Inter | Regular/medium, light gray |
| Labels/Chips | Inter | Medium, accent color |

### Special Widgets

| Widget | Description |
|--------|-------------|
| **NebulaBackground** | Always present, with animated orbs and shifting gradients |
| **GlassCard** | Used for all cards, with customizable border glow |
| **GradientButton** | Animated gradient fill, glowing shadow, and ripple effect on tap |
| **UserAvatar** | Animated gradient border, ambient glow, fallback to initials with neon background |
| **AccentBar** | Thin neon-colored vertical bar for visual section accents |

### Design Summary

| Element | Style/Effect |
|---------|-------------|
| Background | Animated nebula, floating orbs, shifting gradients |
| Cards | Glassmorphic, glowing borders, soft shadows |
| Buttons | Gradient fill, animated glow, rounded corners |
| Avatars | Circular, animated gradient border, ambient glow |
| Navigation | Semi-transparent, neon accent for selected tab |
| Progress | Accent gradient, bold glowing percentage |
| Animations | Fade, scale, slide, Lottie for health/mood/empty states |
| Typography | Poppins (headings, bold, glowing), Inter (body, medium, light gray) |
| Special Widgets | NebulaBackground, GlassCard, GradientButton, UserAvatar, AccentBar |

### AI/Figma Design Prompt

> Design a futuristic, glassmorphic health app UI for **MEDITOUCH**. Use a dark, animated nebula background with floating neon orbs. All cards and sections should be semi-transparent with glowing borders. Accent colors are electric blue, radiant pink, neon green, and vivid orange. Typography is bold Poppins for headings and Inter for body. Buttons and avatars have animated gradient borders and glowing effects. The splash/loading screen features a pulsing glassmorphic circle with a neon health icon, animated gradient background, and glowing app name. All screens should feel immersive, energetic, and modern—like a sci-fi dashboard for health.

### Lottie Animation Prompt

> Create a Lottie animation of a glowing, pulsing glassmorphic circle with a neon blue health icon in the center, floating on an animated nebula background with drifting orbs and a glowing app name below.
