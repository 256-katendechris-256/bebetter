import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'notification_preferences_screen.dart';
import 'downloads_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String displayName;
  final String email;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.displayName,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.ink,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 8,
              right: 18,
              bottom: 14,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Settings',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileCard(displayName: displayName, email: email),
                  const _SectionLabel('Preferences'),
                  _SettingGroup(items: [
                    _SettingItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications & Reminders',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationPreferencesScreen()))),
                    _SettingItem(
                        icon: Icons.palette_outlined,
                        label: 'Appearance & Theme',
                        onTap: () {}),
                    _SettingItem(
                        icon: Icons.language_outlined,
                        label: 'Language',
                        onTap: () {}),
                  ]),
                  const _SectionLabel('Account'),
                  _SettingGroup(items: [
                    _SettingItem(
                        icon: Icons.download_outlined,
                        label: 'Downloads',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DownloadsScreen()))),
                    _SettingItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Privacy & Security',
                        onTap: () {}),
                    _SettingItem(
                        icon: Icons.sync_rounded,
                        label: 'Sync & Backup',
                        onTap: () {}),
                  ]),
                  const _SectionLabel('Support'),
                  _SettingGroup(items: [
                    _SettingItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () {}),
                    _SettingItem(
                        icon: Icons.star_border_rounded,
                        label: 'Rate BookClub',
                        onTap: () {}),
                    _SettingItem(
                        icon: Icons.info_outline_rounded,
                        label: 'About',
                        onTap: () {}),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onLogout();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Log Out',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        foregroundColor: AppColors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String displayName;
  final String email;
  const _ProfileCard({required this.displayName, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(radius: 18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emerald.withOpacity(0.12),
              border:
                  Border.all(color: AppColors.emerald.withOpacity(0.3), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(email,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.9)),
      );
}

class _SettingGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingGroup({required this.items});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: AppDecorations.card(radius: 16),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                ListTile(
                  onTap: e.value.onTap,
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Icon(e.value.icon,
                        size: 20, color: AppColors.textSecondary),
                  ),
                  title: Text(e.value.label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
                if (!isLast)
                  const Divider(
                      height: 1, indent: 62, color: Color(0xFFF3F4F6)),
              ],
            );
          }).toList(),
        ),
      );
}

class _SettingItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
