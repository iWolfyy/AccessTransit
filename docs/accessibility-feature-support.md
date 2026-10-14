# Accessibility preferences and supported behaviour

Wheelchair and step-free preferences feed journey accessibility checks. High contrast and large tap targets affect rendering. Manual boarding assistance remains available through its existing journey action.

Spoken voice navigation, quiet-route matching, automatic haptic travel alerts and automatic boarding-assistance preferences have no connected implementation. Their switches are disabled and labelled unavailable. They cannot be activated by loading old preferences, individual setters or batch saving. Existing stored enabled values are migrated to false.

Walking optimisation is unavailable: the current search uses fixed boarding/alighting stops and has no measured walking paths, entrances or transfer distances. Intermediate bus-stop counts are not walking distance. The old stop-count sort has been removed. Legacy callers requesting minimise walking see a notice, and normal departure/accessibility ordering applies. Search presets do not enable this option. The age-based 'Elderly / Gentle' preset is renamed 'Step-free' to describe what it actually changes.

The interview guide in assignment/milestone-1/02-interview-guide.md covers seating, tolerable walks, assistance and sensory needs without treating all older people as having the same needs. These requirements still need real interviews; this code change does not claim they have been validated.
