# Community feed and upload outbox presentation

Community headings, tabs, actions, empty/error states, contribution summaries,
target fallbacks, freshness/age labels and vote/status badges now use generated
English, Sinhala and Tamil resources. This pass adds 30 resources per locale
and reuses the report-detail/delivery translations. Original target names,
report issues and rider descriptions remain data. Vote thresholds still come
from each report's policy; neither translation nor a community confirmation
establishes independently verified accessibility.

The feed requests surfaced read errors and provides retry guidance instead of
turning a failed read into an empty/safe corridor claim. Its empty state says
that absent reports do not establish accessibility or safety. My Reports
explains sign-in for guests and filters received entries against the current
account, including an old snapshot retained during account switching. Hidden,
disputed and unpublished entries are excluded from the shared feed. Author
review/appeal access stays in the existing review workflow.

Your uploads remains an owner-scoped local section. Its translated disclosure
explains seven-day retention, retry/removal through delivery and sign-out
cleanup. Publication states are translated without altering their stored enum
values. Opening a pending entry uses the same delivery screen and submission
service; it never publishes merely because the user opened it. Production
uses the existing services; optional injection supports isolated tests.

Tabs wrap, the header has additional space at large text sizes, card headers
stack, vote/photo/status chips wrap, and legacy vote buttons retain minimum
heights. Existing theme, report targets and navigation are retained.

New tests cover all three locales at 320dp/200% text, including normal and high
contrast feed cards, error/empty recovery, original content, fifth-False hiding,
guest guidance, stale account snapshots, private upload navigation and account
cleanup. Existing delivery retry/acknowledgement and report voting tests remain
part of focused validation. The clock-refresh regression uses an injected feed
so it tests evidence expiry independently of unavailable Firebase.

No Firebase/Auth mutation, live report publication, hosted deployment, billing
change or APK build/install is included. Fluent translation review and native
font/TalkBack/device QA remain required; other untranslated app text and the
remaining release/data/ETA validation gates are separate work.
