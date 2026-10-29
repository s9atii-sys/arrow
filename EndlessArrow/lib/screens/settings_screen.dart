import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_links.dart';
import '../services/settings_service.dart';
import '../services/sfx_service.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _sound;
  late bool _vibration;

  @override
  void initState() {
    super.initState();
    _sound = SettingsService.instance.soundEnabled;
    _vibration = SettingsService.instance.vibrationEnabled;
  }

  Future<void> _toggleSound(bool value) async {
    setState(() => _sound = value);
    await SettingsService.instance.setSoundEnabled(value);
    if (value) SfxService.instance.playSwipe();
  }

  Future<void> _toggleVibration(bool value) async {
    setState(() => _vibration = value);
    await SettingsService.instance.setVibrationEnabled(value);
  }

  Future<void> _rateUs() async {
    SettingsService.instance.hapticLight();
    final opened = await AppLinks.openRateUs();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.navy,
          content: Text(
            'Could not open the store right now.',
            style: GoogleFonts.fredoka(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _open(Widget page) {
    SettingsService.instance.hapticLight();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PastelBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.navy,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'SETTINGS',
            style: GoogleFonts.fredoka(
              color: AppTheme.navy,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _SettingsCard(
              children: [
                _ToggleRow(
                  icon: Icons.volume_up_rounded,
                  iconColor: const Color(0xFF2196F3),
                  title: 'Sound',
                  subtitle: 'Swipe and game effects',
                  value: _sound,
                  onChanged: _toggleSound,
                ),
                const _CardDivider(),
                _ToggleRow(
                  icon: Icons.vibration_rounded,
                  iconColor: AppTheme.purple,
                  title: 'Vibration',
                  subtitle: 'Haptics on moves',
                  value: _vibration,
                  onChanged: _toggleVibration,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              children: [
                _LinkRow(
                  icon: Icons.policy_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Privacy Policy',
                  onTap: () => _open(const PrivacyPolicyScreen()),
                ),
                const _CardDivider(),
                _LinkRow(
                  icon: Icons.info_rounded,
                  iconColor: const Color(0xFF22C55E),
                  title: 'About Us',
                  onTap: () => _open(const AboutUsScreen()),
                ),
                const _CardDivider(),
                _LinkRow(
                  icon: Icons.star_rounded,
                  iconColor: AppTheme.warning,
                  title: 'Rate Us',
                  onTap: _rateUs,
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Arrow Challenge',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                color: AppTheme.navy.withValues(alpha: 0.45),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Version 1.0.0',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                color: AppTheme.navy.withValues(alpha: 0.32),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoPage(
      title: 'PRIVACY POLICY',
      children: [
        _InfoHeading('Local data'),
        _InfoBody(
          'Arrow Challenge stores your level progress, stars, hints, and '
          'settings on this device only. We do not create an account or ask '
          'for your name, email, or other personal details.',
        ),
        _InfoHeading('Advertising'),
        _InfoBody(
          'The game shows ads through Google AdMob. Google may collect '
          'device identifiers and usage data to serve and measure ads, '
          'subject to Google’s privacy policy.',
        ),
        _InfoHeading('Your choices'),
        _InfoBody(
          'You can turn sound and vibration off at any time in Settings. '
          'Uninstalling the app removes locally stored progress.',
        ),
      ],
    );
  }
}

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoPage(
      title: 'ABOUT US',
      children: [
        _InfoHeading('Arrow Challenge'),
        _InfoBody(
          'A puzzle game of winding arrows. Tap a path to slide it off the '
          'board — but only when its exit is clear. Plan the order, beat '
          'the timer, and work through hundreds of unique mazes.',
        ),
        _InfoHeading('Made for play'),
        _InfoBody(
          'Short sessions, dense boards, and a calm pastel look. Built with '
          'Flutter for Android and iOS.',
        ),
      ],
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PastelBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.navy,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            title,
            style: GoogleFonts.fredoka(
              color: AppTheme.navy,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoHeading extends StatelessWidget {
  const _InfoHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.fredoka(
          color: AppTheme.navy,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoBody extends StatelessWidget {
  const _InfoBody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.fredoka(
          color: AppTheme.navy.withValues(alpha: 0.72),
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.whiteCard(radius: 22),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 18,
      color: Color(0xFFE4E8F7),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          _IconBadge(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.fredoka(
                    color: AppTheme.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.fredoka(
                    color: AppTheme.navy.withValues(alpha: 0.48),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.purple,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          children: [
            _IconBadge(icon: icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.fredoka(
                  color: AppTheme.navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.navy.withValues(alpha: 0.28),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
