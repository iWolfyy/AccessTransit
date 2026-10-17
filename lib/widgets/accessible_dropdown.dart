import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Menu rows and their selected value grow with touch and text preferences.
/// Use with itemHeight: null so translated labels can wrap without clipping.
class AccessibleDropdownMenuItem<T> extends DropdownMenuItem<T> {
  AccessibleDropdownMenuItem({
    super.key,
    super.value,
    super.onTap,
    super.enabled,
    super.alignment,
    required Widget child,
  }) : super(
         child: Builder(
           builder: (context) => ConstrainedBox(
             constraints: BoxConstraints(minHeight: context.buttonHeight),
             child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 8),
               child: Align(
                 alignment: AlignmentDirectional.centerStart,
                 child: child,
               ),
             ),
           ),
         ),
       );
}
