// lib/features/settings_reminders/widgets/reminder_option_widget.dart
import 'package:flutter/material.dart';

class ReminderOptionWidget extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isEnabled;
  final Color? iconColor;

  const ReminderOptionWidget({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isEnabled = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconColor = iconColor ?? (isEnabled ? Theme.of(context).colorScheme.onSurface : Colors.grey);
    final Color effectiveTitleColor = isEnabled ? Theme.of(context).colorScheme.onSurface : Colors.grey;
    final Color? effectiveSubtitleColor = isEnabled ? Theme.of(context).textTheme.bodySmall?.color : Colors.grey;


    return ListTile(
      leading: Icon(leadingIcon, color: effectiveIconColor),
      title: Text(title, style: TextStyle(color: effectiveTitleColor)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: effectiveSubtitleColor)) : null,
      trailing: trailing,
      onTap: isEnabled ? onTap : null,
      enabled: isEnabled,
      contentPadding: EdgeInsets.zero, // Ajustar según sea necesario o eliminar para padding por defecto
    );
  }
}
