import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/localization_context.dart';

/// In-app guidance only; opening help never submits requests or changes data.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final topics = [
      (l.helpSearchTitle, l.helpSearchBody),
      (l.helpSaveTitle, l.helpSaveBody),
      (l.helpLocationTitle, l.helpLocationBody),
      (l.helpLiveTitle, l.helpLiveBody),
      (l.helpReportsTitle, l.helpReportsBody),
      (l.helpVotesTitle, l.helpVotesBody),
      (l.helpAssistanceTitle, l.helpAssistanceBody),
      (l.helpAccessTitle, l.helpAccessBody),
    ];
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(14) > 20
            ? 104
            : 56,
        title: Text(l.profileHelp),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.helpIntro,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < topics.length; i++)
                      Card(
                        color: context.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: context.borderSide,
                        ),
                        child: ExpansionTile(
                          key: PageStorageKey('help-topic-$i'),
                          textColor: context.textColor,
                          collapsedTextColor: context.textColor,
                          iconColor: context.primaryColor,
                          collapsedIconColor: context.primaryColor,
                          title: Text(topics[i].$1),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: [
                            Text(
                              topics[i].$2,
                              style: TextStyle(
                                color: context.textColor,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
