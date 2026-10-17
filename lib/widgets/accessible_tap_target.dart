import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Keeps custom tap regions aligned with the same minimum as Material buttons.
class AccessibleTapTarget extends StatelessWidget {
  const AccessibleTapTarget({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: context.buttonHeight,
      minHeight: context.buttonHeight,
    ),
    child: child,
  );
}
