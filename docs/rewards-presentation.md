# Rewards and membership presentation

Rewards & Contributions and Digital Membership Card use generated English,
Sinhala and Tamil resources for headings, stats, tier labels, points/identity
labels, settings guidance and reward-availability disclosures. This pass adds
28 resources per locale and reuses existing profile and v2 policy wording.

Only known tier labels translate at presentation. Tier derivation still uses
the existing internal labels; translations do not change points, thresholds,
role data or stored values. Unknown supplied tiers, member IDs and custom role
labels remain data. Negative points remain signed. Existing member-name casing
is unchanged.

The legacy points explanation is explicitly historical and appears only in the
legacy branch. The v2 branch keeps its existing author-only reward notice and
server balance refresh behavior. Membership guidance describes the recorded
reward policy without implying every policy requires manual reconciliation.
Points do not verify accessibility or have cash/voucher value; redemption
remains disabled, and no priority support or guaranteed access is promised.

Headers and buttons use minimum heights, full translated titles wrap, chips
wrap and the membership identity/points header stacks on narrow screens or at
large text sizes. Existing theme and normal-size tap-target dimensions remain.

New tests cover all three locales at 320dp/200% text with normal/high contrast:
signed balances, translated Bronze/Gold labels, custom identity/tier values,
card navigation and return, and disabled redemption. Existing reward
availability and touch-target tests remain part of validation. Tests use local
fixture profiles, without real Firebase/Auth writes or balance mutations.

An Android emulator was detected; no new APK was built or installed, and this
does not establish native-device/TalkBack validation of these source changes.
Fluent Sinhala/Tamil review and final physical-device QA remain required.
