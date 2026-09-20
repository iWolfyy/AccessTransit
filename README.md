# AccessTransit - Inclusive Public Transport Companion

**Course:** SE3050 - User Experience Engineering (UEE)  
**Project Status:** Sprint 1 Completed (Production-Ready Codebase)  
**Version:** 1.0.0+1  

---

## 📌 Project Overview
**AccessTransit** is an inclusive public transportation mobile application designed to assist passengers with diverse accessibility requirements (wheelchair users, visually impaired, hearing impaired, elderly, and mobility-assisted passengers). The system establishes real-time connectivity between passengers and transit operators, offering accessible route planning, live bus GPS tracking, priority boarding requests, and crowd-sourced accessibility hazard reporting.

---

## 🚀 How Far We Have Progressed (Sprint 1 Accomplishments)

We have successfully completed **Sprint 1**, building a feature-complete, production-ready Flutter mobile application integrated with **Firebase Authentication**, **Cloud Firestore real-time database**, and **OpenStreetMap (`flutter_map`)** live telemetry tracking.

### 📑 Feature Implementation Matrix

| Module | Feature | Implementation Details | Status |
| :--- | :--- | :--- | :---: |
| **Authentication** | Registration & Login | Firebase Auth, user role assignment (Passenger/Operator), Firestore user profile sync. | ✅ Completed |
| **Authentication** | Password Reset & Deep Links | In-app email recovery, action code extraction via `app_links` (`PasswordResetLinkHandler`). | ✅ Completed |
| **Onboarding** | Accessibility Walkthrough | Interactive multi-page preview detailing transit, mobility, community, and preference features. | ✅ Completed |
| **Home Dashboard** | Quick Actions & Active Journey | Dynamic search bar, quick accessibility filters, live active trip card, live transit feed. | ✅ Completed |
| **Route Planning** | Search & Accessible Routes | Step-free, ramp-accessible, audio-assisted route filtering with route details breakdown. | ✅ Completed |
| **Live Navigation** | OpenStreetMap & Live Telemetry | Interactive `flutter_map` integration, live bus marker movement from `live_locations/{busId}` stream. | ✅ Completed |
| **Dynamic ETA** | Dynamic Telemetry Calculation | Geodesic distance calculation, speed factor adjustment, stale signal handling in `EtaService`. | ✅ Completed |
| **Boarding Assistance** | Priority Boarding Request | One-touch ramp deployment request sent directly to the bus operator dashboard. | ✅ Completed |
| **Operator Dashboard** | Driver Control Center | Real-time assistance request alerts, ramp operational state toggle, occupancy level updates. | ✅ Completed |
| **Community** | Crowd-sourced Hazard Reporting | Incident submission (ramp breakdown, elevator outage, crowding), feed view, upvote system. | ✅ Completed |
| **Preferences** | Accessibility Customization | Visual (High Contrast, Dynamic Font size), Auditory (TTS, voice prompts), Mobility, and Cognitive options. | ✅ Completed |
| **Profile & Pass** | Digital Pass & Rewards | Digital QR membership card, contribution score, achievement badges. | ✅ Completed |
| **Quality Assurance** | Unit Tests & QA Docs | `eta_service_test`, `live_bus_service_test`, `password_reset_link_handler_test`, QA Plan & Tracker. | ✅ Completed |

---

## 🏗 Architecture & Code Structure

```
lib/
├── constants/
│   └── firestore_constants.dart          # Firestore collection & field keys
├── core/
│   ├── routing/
│   │   ├── app_navigation.dart           # Route transitions & navigation helpers
│   │   └── password_reset_link_handler.dart # Deep link parser for password reset
│   ├── theme/
│   │   └── app_colors.dart               # High-contrast accessibility color palette
│   └── utils/
│       └── validators.dart               # Form validation rules (Email, Password, Name)
├── models/
│   ├── bus_location_model.dart           # Real-time bus telemetry model & Firestore converter
│   ├── journey_model.dart                # Passenger booking & trip model
│   ├── user_model.dart                   # Profile model supporting passenger & operator roles
│   └── enums/
│       ├── bus_status.dart               # Bus state (active, offline, delayed)
│       └── user_role.dart                # User roles (passenger, operator)
├── screens/
│   ├── auth/                             # Login, Register, Forgot Password, Reset Password
│   ├── community/                        # Hazard feed & detailed report submission
│   ├── home/                             # Home dashboard, quick actions, active trip card
│   ├── journey/                          # Search, Route Results, Details, Live Map, Assistance
│   ├── onboarding/                       # Multi-stage onboarding wizard
│   ├── operator/                         # Bus Operator dashboard & driver request center
│   ├── preferences/                      # Visual, Auditory, Mobility & Cognitive preferences
│   ├── profile/                          # User profile, Digital Pass QR, Reward points
│   └── splash/                           # Splash screen
├── services/
│   ├── auth_firestore_service.dart       # User profile creation & sync with Firestore
│   ├── auth_service.dart                 # Firebase Auth integration
│   ├── bus_tracking_service.dart        # Bus position tracking provider
│   ├── eta_service.dart                  # Dynamic ETA & geodesic distance math
│   ├── journey_service.dart              # Journey creation, status update & lookup
│   ├── live_bus_service.dart             # Real-time Firestore stream listener & fallback generator
│   ├── location_service.dart             # Device location permissions & GPS provider
│   └── user_service.dart                 # User profile manager
├── widgets/
│   └── auth/                             # Input fields & password strength indicator
└── main.dart                             # App entry point, Firebase init & deep link listener
```

---

## 🧪 Testing & Quality Assurance

### Executing Automated Unit Tests
To run the project test suite, execute:
```bash
flutter test
```

### Key Test Coverage:
1. `test/eta_service_test.dart`: Validates dynamic ETA calculation, geodesic distance calculation, stale signal rejection, and target stop coordinate resolution.
2. `test/live_bus_service_test.dart`: Tests real-time Firestore stream transformations and fallback telemetry generation.
3. `test/password_reset_link_handler_test.dart`: Validates deep link action code parsing from incoming authentication URIs.

### QA Documentation Assets
- **`Sprint1_QA_Test_Plan.docx`**: Full specification of test suites, test cases, and expected behaviors across all user roles.
- **`Sprint1_QA_Tracker.xlsx`**: Detailed test execution log, status reports, and acceptance criteria verification.

---

## 🔮 Roadmap & Next Steps (Sprint 2 Features)
- [ ] **Voice Control & Audio Commands**: Hands-free navigation trigger using Speech-to-Text.
- [ ] **Offline Map Tile Caching**: Map tile persistence for low-connectivity rural routes.
- [ ] **NFC Transit Pass Reader**: Integration for contactless driver-side validation.
- [ ] **Multilingual Support**: Localization for English, Sinhala, and Tamil languages.

---

## 💻 How to Run the Project Locally

### Prerequisites
- Flutter SDK (`^3.13.0`)
- Android Studio / VS Code with Flutter & Dart extensions
- Connected Android Device or Emulator with Google Play Services

### Setup Commands
```bash
# 1. Navigate to the project directory
cd AccessTransit

# 2. Fetch dependencies
flutter pub get

# 3. Run unit tests
flutter test

# 4. Launch the application
flutter run
```
