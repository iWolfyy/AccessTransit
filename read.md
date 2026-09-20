# AccessTransit - Project Status & Documentation (read.md)

> Note: For the full markdown documentation with diagrams and tables, please see [README.md](file:///e:/Y3%20S2/UEE/AccessTransit/README.md).

## 🚀 How Far We Have Progressed

We have successfully completed **Sprint 1** for the **AccessTransit** (SE3050 - User Experience Engineering) project. The app is a fully functional, production-ready Flutter mobile application built with Firebase and OpenStreetMap integration.

### Summary of Completed Features:
1. **Authentication & User Management**:
   - Email/password login and registration.
   - User role designation (`Passenger` vs `Operator/Bus Driver`).
   - Password reset via deep links (`app_links`).
   - Firestore user profile persistence (`users/{uid}`).

2. **Onboarding & Accessibility Guidance**:
   - Multi-step interactive feature walkthrough.
   - Tailored previews for wheelchair accessibility, audio navigation, and community hazard reporting.

3. **Home Dashboard & Quick Actions**:
   - Location status and accessible search bar.
   - Active journey card with instant trip resumption.
   - Accessibility quick filter shortcuts (Wheelchair step-free, Audio prompts, High Contrast).
   - Live transit arrival feed.

4. **Journey Planning & Real-Time Navigation**:
   - Destination search with accessibility filter toggles.
   - Accessible route comparison and step-by-step breakdown.
   - Live OpenStreetMap (`flutter_map`) tracking with real-time bus marker movements.
   - Dynamic ETA calculation (`EtaService`) using geodesic distance math, bus speed, and signal freshness validation.

5. **Boarding Assistance & Driver Dashboard**:
   - Passenger priority boarding request feature (ramp request, visual assistance).
   - Real-time bus operator dashboard (`OperatorDashboardScreen`) receiving passenger requests, updating occupancy levels, and toggling ramp availability.

6. **Community Crowdsourcing**:
   - Incident & hazard reporting (broken ramp, elevator outage, overcrowding).
   - Upvoting system and report status tracking.

7. **Preferences & Customization**:
   - Visual settings (High contrast mode, dynamic text size).
   - Auditory settings (TTS voice guidance, screen reader optimization).
   - Mobility & Cognitive customized settings.

8. **Digital Pass & Rewards**:
   - Digital QR membership card.
   - User contribution scores & community scout badges.

9. **Automated Testing & QA Documentation**:
   - Unit tests: `eta_service_test.dart`, `live_bus_service_test.dart`, `password_reset_link_handler_test.dart`.
   - QA deliverables: `Sprint1_QA_Test_Plan.docx` and `Sprint1_QA_Tracker.xlsx`.

---
### Project File Tree
- Main app source code: [lib/](file:///e:/Y3%20S2/UEE/AccessTransit/lib/)
- Comprehensive Documentation: [README.md](file:///e:/Y3%20S2/UEE/AccessTransit/README.md)
- Automated Unit Tests: [test/](file:///e:/Y3%20S2/UEE/AccessTransit/test/)