# Condition freshness

These are initial product defaults, to validate through commuter/operator research:

- Crowding, seats and wheelchair bay availability: 30 minutes.
- Driver assistance, reckless driving and temporary blockages: 2 hours.
- Cleanliness: 6 hours.
- Other conditions and working accessibility equipment: 24 hours.

Broken/damaged equipment, elevator faults, missing tactile paving and unsafe gaps remain unresolved until the existing resolve action marks the report resolved (or community flags hide it). After the condition's freshness window, they remain planning warnings labelled **Unresolved barrier — needs recheck**. They are historical evidence of a fault, not proof that equipment is still broken or repaired. Positive reports do not silently resolve faults.

Last checked uses the original observation time, or a later community confirmation with an identified account and valid timestamp. Missing/future/earlier confirmation timestamps do not renew freshness. Confirmation refreshes the condition's own window. High crowding attached to another condition has its own 30-minute window: it stops overriding a working ramp once old, and does not erase a broken ramp.

Route evidence, public report cards and report details display last checked/recheck information. Resolved, hidden, future, unpublished and demo observations cannot affect planning. No new Firestore fields or migration are required: existing status, createdAt, lastConfirmedAt and confirmedBy carry the lifecycle.
