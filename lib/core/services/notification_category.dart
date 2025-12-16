import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationCategory {
  reminder;

  String get channelId {
    switch (this) {
      case NotificationCategory.reminder:
        return 'reminder_channel';
    }
  }

  String get channelName {
    switch (this) {
      case NotificationCategory.reminder:
        return 'Reminder Notifications';
    }
  }

  String get channelDescription {
    switch (this) {
      case NotificationCategory.reminder:
        return 'Daily reminders to record transactions';
    }
  }

  AndroidNotificationDetails toAndroidDetails({
    String? icon,
    List<AndroidNotificationAction>? actions,
    AndroidNotificationSound? sound,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: icon ?? '@mipmap/launcher_icon',
      sound:
          sound ??
          const RawResourceAndroidNotificationSound('notification_sound'),
      actions: actions,
    );
  }

  DarwinNotificationDetails toIOSDetails() {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.mp3', // iOS usually needs extension
    );
  }
}
