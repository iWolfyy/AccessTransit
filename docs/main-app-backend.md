# Main app implementation and trusted backend

Latest agreement, 2026-10-17: use the main Android app with real Firebase
Auth/Firestore and run trusted server operations on the development computer.
Defer Functions deployment and billing changes. Main-app debug localhost support
and the real-project server launcher are now implemented in checkpoint 44; see
[running the real-project localhost backend](localhost-real-firebase.md).
The old loopback launcher intentionally supports only synthetic demo emulators.
Do not redirect demo seed/reset scripts to the real project. Release transport
remains HTTPS-only. The HTTPS and billing preflight below records the preceding
checkpoint. Checkpoint 44 records the later authorized Firestore rules/indexes,
trusted admin claim, zero-baseline policy activation and ready localhost service.

Confirmed workflow, 2026-10-17: continue in the main application and existing real
Firebase project `accesstransit-b615b`. Build the main APK at final delivery.
Do not generate/install separate Local Test APKs or intermediate APKs.
Automated Flutter and isolated backend/emulator tests remain verification tools.
Existing real user/catalogue data must be preserved; synthetic fixtures and reset
scripts must never target this project.

The normal app already initializes `DefaultFirebaseOptions`, using real Firebase
Auth and Firestore. An APK build or installation is not a Firestore deployment.
Changing source, deploying security rules, provisioning reviewed data and
deploying the trusted server are separate operations. Prior local test results
do not prove shared rules/functions or a new app version are running.

Main-app moderation v2 is now configurable in debug and release with
`MODERATION_V2=true` and `MODERATION_API_ORIGIN` set to the deployed service's
trusted HTTPS origin. An origin contains the scheme/host and optional port, not
an API path, credentials, query or fragment. Requests append `/v2/...`; use the
actual HTTPS origin returned by the hosting rollout or its reviewed proxy.
There is no real endpoint value in the repository yet. Do not substitute an
example URL, invent an endpoint or silently fall back to emulator HTTP.

Activation no longer requires `LOCAL_VALIDATION`. The configured main-app origin
is used by the existing publication/voting, account gate, moderation/appeal,
assistance and administrator operations. The requested v2 mode fails startup
when its endpoint is missing/invalid. Until the real service and matching
rules/migration are ready and v2 is configured, the existing default flow remains
unchanged. The flag alone does not create a backend or grant administrator claims.

The fixed emulator HTTP exception is retained only for explicit automated debug
tests. Main HTTPS activation cannot grant it. Android always uses the main
application ID and real Google Services configuration; the old native
`LOCAL_VALIDATION=true` command is rejected before assembly. Removing the suffix
alone would have risked replacing the main installed app with a synthetic-data
app; the rejection prevents that. No app was built, installed or uninstalled in
this change.

## Functions and billing preflight

Firebase Functions is the user's confirmed hosting choice. The read-only checks
against the existing project on 2026-10-17 found:

- Cloud Billing reports `billingEnabled: false` and no linked billing account
  (`phase28-billing-preflight.log`). No billing-account identity was printed.
- Cloud Functions inventory returned HTTP 403 `SERVICE_DISABLED`, indicating its
  API is disabled (`phase28-functions-inventory.log` and the CLI diagnostic).

`test/security/read-shared-billing.mjs` uses the existing Firebase CLI sign-in
to GET the fixed project's billing status and prints only a sanitized result.
It never associates billing, upgrades plans, enables APIs, deploys or reads user
records. Avoid the CLI's internal billing helper for this read: it also ensures
the billing API is enabled, which is outside a read-only check.

At checkpoint 42 no billing/API changes, live rules/functions deployment,
migration or real Firestore record write were performed. The later checkpoint
44 records the authorized shared Firestore/admin/config updates, while billing
and Functions remain unchanged. Enabling hosted Functions needs the billing
setup, a prepared deployment package/worker configuration, migration preflight,
reviewed rules/indexes and actual authenticated runtime verification. Auth
disable/delete and automatic server operations cannot be implemented as an
unrestricted Flutter write to Firestore. Real push testing remains deferred.
