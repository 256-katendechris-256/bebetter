enum NotificationType {
  streak('streak'),
  league('league'),
  goal('goal'),
  achievement('achievement'),
  bookclub('bookclub');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => NotificationType.bookclub,
    );
  }
}

enum NotificationUrgency {
  low('low'),
  medium('medium'),
  high('high');

  final String value;
  const NotificationUrgency(this.value);

  static NotificationUrgency fromString(String value) {
    return NotificationUrgency.values.firstWhere(
      (u) => u.value == value,
      orElse: () => NotificationUrgency.low,
    );
  }
}

class NotificationLog {
  final int id;
  final NotificationType notifType;
  final NotificationUrgency urgency;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime sentAt;
  final bool opened;

  NotificationLog({
    required this.id,
    required this.notifType,
    required this.urgency,
    required this.title,
    required this.body,
    this.data,
    required this.sentAt,
    required this.opened,
  });

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      id: json['id'] as int,
      notifType: NotificationType.fromString(json['notif_type'] as String),
      urgency: NotificationUrgency.fromString(json['urgency'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      sentAt: DateTime.parse(json['sent_at'] as String),
      opened: json['opened'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'notif_type': notifType.value,
        'urgency': urgency.value,
        'title': title,
        'body': body,
        'data': data,
        'sent_at': sentAt.toIso8601String(),
        'opened': opened,
      };
}

class NotificationPreferences {
  final bool streakAlerts;
  final bool leagueAlerts;
  final bool goalReminders;
  final String? reminderTime;
  final String? timezone;

  NotificationPreferences({
    required this.streakAlerts,
    required this.leagueAlerts,
    required this.goalReminders,
    this.reminderTime,
    this.timezone,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      streakAlerts: json['streak_alerts'] as bool? ?? true,
      leagueAlerts: json['league_alerts'] as bool? ?? true,
      goalReminders: json['goal_reminders'] as bool? ?? true,
      reminderTime: json['reminder_time'] as String?,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'streak_alerts': streakAlerts,
        'league_alerts': leagueAlerts,
        'goal_reminders': goalReminders,
        'reminder_time': reminderTime,
        'timezone': timezone,
      };

  NotificationPreferences copyWith({
    bool? streakAlerts,
    bool? leagueAlerts,
    bool? goalReminders,
    String? reminderTime,
    String? timezone,
  }) {
    return NotificationPreferences(
      streakAlerts: streakAlerts ?? this.streakAlerts,
      leagueAlerts: leagueAlerts ?? this.leagueAlerts,
      goalReminders: goalReminders ?? this.goalReminders,
      reminderTime: reminderTime ?? this.reminderTime,
      timezone: timezone ?? this.timezone,
    );
  }
}
