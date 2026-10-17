# Driver operational presentation

The driver dashboard and approval/route gates use generated English, Sinhala
and Tamil resources. The pass covers dated departures, late reasons, start/stop
and departure actions, GPS publication feedback, vehicle observations, route
progress, timetable/ETA labels, delay notices and legacy assistance summaries.
There are 180 new resources per locale. This is presentation work; the trip
timing, authorization, locks, acknowledged mutations and ETA calculations stay
in the existing services and calculator.

`DriverDatedDepartureCard`, `DriverTripControlCard`, `DriverTelemetryCard`,
`DriverVehicleStatusCard`, `DriverLateStartDialog` and `DriverDelaySheet` are
the presentation widgets used by the main dashboard. They do not create
Firebase clients or request GPS. The dashboard passes state and keeps the
operational subscriptions and mutations. No alternate app or test APK is added.

Fixed UI labels are translated through `driver_presentation.dart`. Bus/route
IDs, run states, boolean observations, occupancy values and delay reasons sent
to the backend retain their existing values. Route/stop/rider names and custom
reason text remain original. Selected delay reason/minutes survive a locale
change while the sheet is open. Unknown run states and unknown countdown
contracts display unavailable wording instead of exposing a raw enum or
inventing a live estimate.

GPS feedback distinguishes local coordinates, pending uploads, acknowledged
shared fixes, stale fixes and failed completion. Failed claim, ramp, occupancy,
start, stop, arrival and delay writes use localized retry messages without raw
exception details. A positive acknowledgement is still shown only after the
existing operation completes. The foreground-service tracking notification
uses the locale captured when tracking starts.

ETA display uses the existing calculator's unavailable/scheduled/live
distinction and countdown minutes. Localization does not improve ETA accuracy
or add traffic/geometry evidence. Calendar dates remain explicit on other-day
arrivals; time-of-day formatting uses Material localization. Legacy assistance
rows show explicit Colombo creation timestamps and reuse existing assistance
type/status translations.

Automated coverage exercises the production widgets in all three locales at
320dp/200% text, stable backend values, locale changes, exact start boundaries,
busy/read-only controls, stale GPS, unknown states, failed vs empty run loads,
reason collection and cancellation. Stream fixtures verify that revoked
approval or route access withdraws operation controls. Existing transaction,
delivery and delay regressions also run. These tests do not operate a real bus
or mutate real accounts.

Fluent Sinhala/Tamil review and a complete native dashboard/font/TalkBack,
keyboard and background-GPS walkthrough remain release gates. Other screens,
including the shared Add Station editor, retain their own localization scope;
this pass does not claim whole-app translation completion. No APK build,
shared Firebase change, deployment, billing change or real push test is part
of this pass.
