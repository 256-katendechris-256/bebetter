import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

const Color kInk          = Color(0xFF0D1B2A);
const Color kEmerald      = Color(0xFF059669);
const Color kEmeraldSoft  = Color(0xFFECFDF5);
const Color kSurface      = Color(0xFFFFFFFF);
const Color kBg           = Color(0xFFF4F6F8);
const Color kTextPrimary  = Color(0xFF111827);
const Color kTextSecondary= Color(0xFF6B7280);
const Color kTextMuted    = Color(0xFF9CA3AF);

BoxDecoration _card({double radius = 16}) => BoxDecoration(
  color      : kSurface,
  borderRadius: BorderRadius.circular(radius),
  boxShadow  : const [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
  ],
);

// ═════════════════════════════════════════════════════════════════════════════
// NOTIFICATION PREFERENCES SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final _api = ApiService();

  bool   _streakAlerts  = true;
  bool   _leagueAlerts  = true;
  bool   _goalReminders = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);
  bool   _loading  = true;
  bool   _saving   = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final res = await _api.getNotificationPreferences();
      if (res.statusCode == 200 && mounted) {
        final data = res.data as Map<String, dynamic>;
        final timeStr = (data['reminder_time'] as String?) ?? '07:00';
        final parts   = timeStr.split(':');
        setState(() {
          _streakAlerts  = data['streak_alerts']  ?? true;
          _leagueAlerts  = data['league_alerts']  ?? true;
          _goalReminders = data['goal_reminders'] ?? true;
          _reminderTime  = TimeOfDay(
            hour  : int.tryParse(parts[0]) ?? 7,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final h   = _reminderTime.hour.toString().padLeft(2, '0');
      final m   = _reminderTime.minute.toString().padLeft(2, '0');
      await _api.updateNotificationPreferences({
        'streak_alerts' : _streakAlerts,
        'league_alerts' : _leagueAlerts,
        'goal_reminders': _goalReminders,
        'reminder_time' : '$h:$m:00',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content        : const Text('Preferences saved'),
            backgroundColor: kEmerald,
            behavior       : SnackBarBehavior.floating,
            margin         : const EdgeInsets.all(16),
            shape          : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content        : const Text('Failed to save — please try again'),
            backgroundColor: Colors.red,
            behavior       : SnackBarBehavior.floating,
            margin         : const EdgeInsets.all(16),
            shape          : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context    : context,
      initialTime: _reminderTime,
      builder    : (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary  : kEmerald,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor         : kInk,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            color  : kInk,
            padding: EdgeInsets.only(
              top   : MediaQuery.of(context).padding.top + 12,
              left  : 8,
              right : 16,
              bottom: 14,
            ),
            child: Row(
              children: [
                IconButton(
                  icon     : const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Notifications & Reminders',
                      style: TextStyle(
                          fontSize    : 17,
                          fontWeight  : FontWeight.w800,
                          color       : Colors.white,
                          letterSpacing: -0.3)),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(color: kEmerald))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Alerts section ───────────────────────
                  _SectionLabel('Alert Types'),
                  Container(
                    decoration: _card(),
                    child: Column(children: [
                      _PrefToggle(
                        icon   : Icons.local_fire_department_rounded,
                        color  : const Color(0xFFF97316),
                        title  : 'Streak Alerts',
                        sub    : '9PM warning + 11:30PM SOS when streak is at risk',
                        value  : _streakAlerts,
                        onChanged: (v) => setState(() => _streakAlerts = v),
                      ),
                      _Divider(),
                      _PrefToggle(
                        icon   : Icons.emoji_events_rounded,
                        color  : const Color(0xFFF59E0B),
                        title  : 'League Alerts',
                        sub    : 'Get notified when someone overtakes you in XP',
                        value  : _leagueAlerts,
                        onChanged: (v) => setState(() => _leagueAlerts = v),
                      ),
                      _Divider(),
                      _PrefToggle(
                        icon   : Icons.menu_book_rounded,
                        color  : kEmerald,
                        title  : 'Reading Reminders',
                        sub    : 'Daily nudge at your chosen time',
                        value  : _goalReminders,
                        onChanged: (v) => setState(() => _goalReminders = v),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // ── Reminder time ────────────────────────
                  _SectionLabel('Daily Reminder Time'),
                  GestureDetector(
                    onTap: _goalReminders ? _pickTime : null,
                    child: Container(
                      decoration: _card(),
                      padding   : const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width : 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color       : kEmerald.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.access_time_rounded,
                                color: _goalReminders
                                    ? kEmerald
                                    : kTextMuted,
                                size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Remind me at',
                                    style: TextStyle(
                                        fontSize  : 14,
                                        fontWeight: FontWeight.w500,
                                        color     : _goalReminders
                                            ? kTextPrimary
                                            : kTextMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  _reminderTime.format(context),
                                  style: TextStyle(
                                      fontSize  : 22,
                                      fontWeight: FontWeight.w800,
                                      color     : _goalReminders
                                          ? kEmerald
                                          : kTextMuted),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: _goalReminders
                                  ? kTextMuted
                                  : kTextMuted.withOpacity(0.4)),
                        ],
                      ),
                    ),
                  ),

                  if (!_goalReminders)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        'Enable Reading Reminders above to set a time.',
                        style: TextStyle(
                            fontSize: 12, color: kTextMuted),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // ── Save button ──────────────────────────
                  SizedBox(
                    width : double.infinity,
                    height: 52,
                    child : ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style    : ElevatedButton.styleFrom(
                        backgroundColor: kEmerald,
                        foregroundColor: Colors.white,
                        elevation      : 0,
                        shape          : RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                          ? const SizedBox(
                        width : 20,
                        height: 20,
                        child : CircularProgressIndicator(
                            color    : Colors.white,
                            strokeWidth: 2),
                      )
                          : const Text('Save Preferences',
                          style: TextStyle(
                              fontSize  : 15,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
    child  : Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize    : 11,
            fontWeight  : FontWeight.w700,
            color       : kTextMuted,
            letterSpacing: 0.9)),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
      height: 1, indent: 62, color: Color(0xFFF3F4F6));
}

class _PrefToggle extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   sub;
  final bool     value;
  final ValueChanged<bool> onChanged;

  const _PrefToggle({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child  : Row(
      children: [
        Container(
          width : 36,
          height: 36,
          decoration: BoxDecoration(
            color       : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize  : 14,
                      fontWeight: FontWeight.w600,
                      color     : kTextPrimary)),
              const SizedBox(height: 2),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 12, color: kTextSecondary)),
            ],
          ),
        ),
        Switch(
          value           : value,
          onChanged       : onChanged,
          activeColor     : kEmerald,
          activeTrackColor: kEmerald.withOpacity(0.3),
        ),
      ],
    ),
  );
}