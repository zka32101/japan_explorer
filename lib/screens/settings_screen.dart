import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:japanaut_kit/japanaut_kit.dart' show LegalText;
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_brand.dart';
import '../config/theme.dart';
import '../providers/language_provider.dart';
import '../providers/offline_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {
      // Non-fatal: version falls back to '—'
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.title'))),
      body: ListView(
        children: [
          // ── Appearance ───────────────────────────────────────────────────
          _SectionHeader(
              title: tr('settings.appearance'), icon: Icons.palette_outlined),
          _ThemeTile(currentMode: settings.themeMode),
          const Divider(height: 1),

          // ── Notifications ────────────────────────────────────────────────
          _SectionHeader(
              title: tr('settings.notifications'),
              icon: Icons.notifications_outlined),
          SwitchListTile(
            secondary: const Icon(Icons.local_fire_department_outlined),
            title: Text(tr('settings.notif_streak')),
            subtitle: Text(tr('settings.notif_streak_desc')),
            value: settings.notifStreak,
            onChanged: (_) =>
                ref.read(settingsProvider.notifier).toggleNotifStreak(),
            activeThumbColor: AppColors.primary,
          ),
          const Divider(height: 1, indent: 72),
          SwitchListTile(
            secondary: const Icon(Icons.quiz_outlined),
            title: Text(tr('settings.notif_challenge')),
            subtitle: Text(tr('settings.notif_challenge_desc')),
            value: settings.notifChallenge,
            onChanged: (_) =>
                ref.read(settingsProvider.notifier).toggleNotifChallenge(),
            activeThumbColor: AppColors.primary,
          ),
          const Divider(height: 1, indent: 72),
          SwitchListTile(
            secondary: const Icon(Icons.handshake_outlined),
            title: Text(tr('settings.notif_meetup')),
            subtitle: Text(tr('settings.notif_meetup_desc')),
            value: settings.notifMeetup,
            onChanged: (_) =>
                ref.read(settingsProvider.notifier).toggleNotifMeetup(),
            activeThumbColor: AppColors.primary,
          ),
          const Divider(height: 1),

          // ── Language ─────────────────────────────────────────────────────
          _SectionHeader(
              title: tr('settings.language'), icon: Icons.language_outlined),
          Consumer(
            builder: (context, ref, _) {
              final currentLang = ref.watch(languageProvider);
              return ListTile(
                leading: const Icon(Icons.translate_outlined),
                title: Text(tr('settings.app_language')),
                subtitle: Text(currentLang.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(ref),
              );
            },
          ),
          const Divider(height: 1),

          // ── Offline Content ──────────────────────────────────────────────
          _SectionHeader(
              title: tr('offline.section_title'),
              icon: Icons.download_outlined),
          Consumer(builder: (context, ref, _) {
            final offlineState = ref.watch(offlineSyncProvider);
            return ListTile(
              leading: const Icon(Icons.offline_pin_outlined),
              title: Text(tr('offline.manage_title')),
              subtitle: Text(offlineState.hasSynced
                  ? '${formatStorageMb(offlineState.storageMb)} ${tr('offline.downloaded')}'
                  : tr('offline.not_downloaded')),
              trailing: offlineState.hasSynced
                  ? const Icon(Icons.check_circle,
                      color: Colors.green, size: 20)
                  : const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.offlineContent),
            );
          }),
          const Divider(height: 1),

          // ── Data & Privacy ───────────────────────────────────────────────
          _SectionHeader(
              title: tr('settings.data_privacy'),
              icon: Icons.security_outlined),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: Text(tr('settings.clear_scan_history')),
            subtitle: Text(tr('settings.clear_scan_history_desc')),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showClearHistoryDialog,
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(tr('settings.privacy_policy')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showTextPage(context, tr('settings.privacy_policy'), LegalText.privacy(tripBrand,
                    collectedUsage: 'spots you view, plans you create, and features you use')),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(tr('settings.delete_account'),
                style: const TextStyle(color: Colors.red)),
            subtitle: Text(tr('settings.delete_account_desc')),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: _showDeleteAccountDialog,
          ),
          const Divider(height: 1),

          // ── About ────────────────────────────────────────────────────────
          _SectionHeader(title: tr('settings.about'), icon: Icons.info_outline),
          ListTile(
            leading: const Icon(Icons.apps_outlined),
            title: Text(tr('settings.version_label')),
            trailing: Text(
              _version.isEmpty ? '—' : '$_version+$_buildNumber',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const Divider(height: 1, indent: 72),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(tr('settings.terms')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showTextPage(context, tr('settings.terms'), LegalText.terms(tripBrand,
                    serviceSummary:
                        'cultural information, travel planning tools, and AI-powered features for visitors to Japan')),
          ),
          const SizedBox(height: 36),
          Center(
            child: Text(
              tr('settings.copyright'),
              style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  void _showLanguageDialog(WidgetRef ref) {
    final currentLang = ref.read(languageProvider);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('settings.app_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final lang in Language.values)
              _LangTile(
                flag: lang.flag,
                name: lang.displayName,
                selected: currentLang == lang,
                onTap: () {
                  // MaterialApp follows languageProvider (see main.dart).
                  ref.read(languageProvider.notifier).setLanguage(lang);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('common.cancel')),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('settings.clear_scan_history_title')),
        content: Text(tr('settings.clear_scan_history_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // ScanHistoryRepository exposes a clear() method;
              // wire it here once you expose it via a provider.
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('settings.scan_history_cleared'))),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('settings.clear')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: Colors.red, size: 36),
        title: Text(tr('settings.delete_account_title')),
        content: Text(tr('settings.delete_account_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Trigger server-side account deletion (Cloud Function)
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('settings.delete_account_processing')),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr('settings.delete_forever')),
          ),
        ],
      ),
    );
  }

  void _showTextPage(BuildContext context, String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language tile ─────────────────────────────────────────────────────────────

class _LangTile extends StatelessWidget {
  final String flag;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.flag,
    required this.name,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(name),
      selected: selected,
      selectedColor: AppColors.primary,
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

// ── Theme picker tile ─────────────────────────────────────────────────────────

class _ThemeTile extends ConsumerWidget {
  final ThemeMode currentMode;
  const _ThemeTile({required this.currentMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(_icon(currentMode)),
      title: Text(tr('settings.theme')),
      subtitle: Text(_label(currentMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showPicker(context, ref),
    );
  }

  IconData _icon(ThemeMode m) => switch (m) {
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        _ => Icons.brightness_auto_outlined,
      };

  String _label(ThemeMode m) => switch (m) {
        ThemeMode.dark => tr('settings.theme_dark'),
        ThemeMode.light => tr('settings.theme_light'),
        _ => tr('settings.theme_system'),
      };

  void _showPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('settings.choose_theme'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                value: mode,
                groupValue: currentMode,
                secondary: Icon(_icon(mode)),
                title: Text(_label(mode)),
                fillColor: WidgetStateProperty.all(AppColors.primary),
                onChanged: (m) {
                  if (m != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(m);
                    Navigator.pop(ctx);
                  }
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
