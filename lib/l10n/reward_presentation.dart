import 'package:flutter/widgets.dart';

import 'localization_context.dart';

/// Translate known tier labels at presentation; unknown supplied labels stay data.
extension RewardPresentation on BuildContext {
  String rewardTier(String value) => switch (value) {
    'Gold Contributor' => l10n.rewardsGold,
    'Silver Contributor' => l10n.rewardsSilver,
    'Bronze Contributor' => l10n.rewardsBronze,
    'Gold Member' => l10n.memberGold,
    'Silver Member' => l10n.memberSilver,
    'Bronze Member' => l10n.memberBronze,
    _ => value,
  };
}
