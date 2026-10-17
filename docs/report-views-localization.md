# Report Details and publication delivery presentation

Report Details and the publication delivery/retry screen now use generated
English/Sinhala/Tamil resources. This pass adds 100 entries per locale for
fixed labels, condition/status wording, legacy mutation receipts, delivery
states and errors, and typed sharing/count/time parameters. Original report
titles, rider notes, target names and stored category/severity keys remain
data. Known category/severity labels are translated only in the view.

The hidden-report message uses the report's policy threshold: five for v2,
three for historical v1. A community dispute does not prove a condition false.
Resolved wording describes the author's recorded observation rather than
claiming an independently verified repair. Active/expired wording describes
the observation without claiming live telemetry or an archival operation.
The v2 voting widget already had localized resources; those are reused and
tested alongside the new views. Backend moderation/reward policies are
unchanged, and authors still cannot vote True or False on their own report.

Delivery distinguishes pending/failed/local-only drafts from acknowledged
publication. Known service errors are translated, valid cooldown deadlines
retain their UTC timestamp, and unknown error text becomes generic retry
guidance rather than displaying a provider message. This does not change
outbox persistence, retry IDs, retention, account scoping or server acceptance.
Original observation content stays hidden after a pending draft's account
changes. Legacy confirmation/recheck/resolution receipts are localized after
their existing acknowledged mutation returns.

Sharing copies localized alert text containing the original condition and
target. It now waits for Clipboard.setData before showing success, handles
failure and makes no claim that a link was copied. Status, target, category
and note labels wrap at large text sizes; legacy action buttons can grow to
their text while retaining minimum touch heights and existing theme styles.
Photo headings, unavailable-image labels and enlarge badges also wrap within
the narrow screen instead of extending beyond the card.

New isolated tests cover all three locales at 320dp/200% text/high contrast:
original report text, author vote exclusion, the five-vote hidden message,
False-reason validation, delayed vote/publication acknowledgements, account
changes, safe error/cooldown presentation and delayed clipboard receipts.
Existing v2, legacy mutation and delivery layout regressions remain in use.
HTTP, storage, report streams and clipboard operations are fixture-controlled;
there is no live Firebase mutation or real clipboard change in these tests.

The report-entry form's condition/category catalogue, camera/gallery controls
and review dialog remain the next translation slice. Fluent Sinhala/Tamil
review and native font/TalkBack/device QA are still required. No deployment,
Auth/billing change, push send or APK build/install is part of this pass.
