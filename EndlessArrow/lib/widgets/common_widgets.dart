import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const bg = Color(0xFFDCE1F5);
  static const navy = Color(0xFF2D3561);
  static const purple = Color(0xFF8B3DFF);
  static const purpleLight = Color(0xFFA855F7);
  static const purpleDark = Color(0xFF5B21B6);
  static const heartRed = Color(0xFFFF3B5C);
  static const warning = Color(0xFFFFC831);
  static const success = Color(0xFF22C55E);

  // Clean cool white-wood palette — borderless, minimal shadow.
  static const whiteWoodTop = Color(0xFFFFFFFF);
  static const whiteWoodHigh = Color(0xFFFAFAF8);
  static const whiteWoodMid = Color(0xFFF5F3F0);
  static const whiteWoodLow = Color(0xFFEEEAE6);
  static const woodInk = Color(0xFF6B635A);

  static BoxDecoration woodPanel({
    double radius = 14,
    bool urgent = false,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: urgent
              ? const [Color(0xFFFFF8F6), Color(0xFFFAF0EC), Color(0xFFF5E8E4)]
              : const [whiteWoodTop, whiteWoodHigh, whiteWoodMid, whiteWoodLow],
          stops: urgent ? null : const [0.0, 0.35, 0.7, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142D3561),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      );

  static BoxDecoration woodButton({bool primary = true}) => BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: primary
              ? const [whiteWoodTop, whiteWoodHigh, whiteWoodMid]
              : const [Color(0xFFFAFAF8), Color(0xFFF3F1EE), Color(0xFFECE8E4)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x122D3561),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      );

  static BoxDecoration woodDialogShell({double radius = 26}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [whiteWoodTop, whiteWoodHigh, whiteWoodMid],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x182D3561),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      );

  static BoxDecoration whiteCard({double radius = 20}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x262D3561),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      );
}

/// Soft lavender background with pastel blobs, shared by every screen.
class PastelBackground extends StatelessWidget {
  const PastelBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.bg,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _BlobPainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void blob(Color color, Offset center, double radius) {
      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawCircle(center, radius, paint);
    }

    blob(const Color(0xFFF6E3A1), Offset(w * 1.02, h * 0.04), w * 0.28);
    blob(const Color(0xFFC9E6F7), Offset(w * 0.08, h * 0.03), w * 0.24);
    blob(const Color(0xFFE2CDF3), Offset(-w * 0.08, h * 0.48), w * 0.30);
    blob(const Color(0xFFC4D2F6), Offset(w * 1.06, h * 0.62), w * 0.32);
    blob(const Color(0xFFF3CDE8), Offset(w * 1.0, h * 0.96), w * 0.26);
    blob(const Color(0xFFEFF2FD), Offset(w * 0.15, h * 1.0), w * 0.28);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Rounded wooden control used in the game header (back, reload, timer).
class WoodControlButton extends StatelessWidget {
  const WoodControlButton({
    super.key,
    required this.child,
    required this.onTap,
    this.urgent = false,
    this.width = 50,
    this.height = 50,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool urgent;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: AppTheme.woodPanel(radius: 14, urgent: urgent),
        child: Center(child: child),
      ),
    );
  }
}

/// Failure / pause dialog with pastel inner panel and wooden frame + buttons.
class WoodGameDialog extends StatelessWidget {
  const WoodGameDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: AppTheme.woodDialogShell(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.fredoka(
                  color: AppTheme.woodInk,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  color: AppTheme.woodInk.withValues(alpha: 0.72),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WoodDialogButton extends StatelessWidget {
  const WoodDialogButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: AppTheme.woodButton(primary: primary),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              color: AppTheme.woodInk,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

enum _ChunkyButtonTone { purple, blue, coral }

/// Chunky rounded button. Purple by default; [blue] for PLAY, [coral] for
/// SETTINGS.
class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.blue = false,
    this.coral = false,
    this.fontSize = 22,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool blue;
  final bool coral;
  final double fontSize;
  final double? width;

  _ChunkyButtonTone get _tone {
    if (coral) return _ChunkyButtonTone.coral;
    if (blue) return _ChunkyButtonTone.blue;
    return _ChunkyButtonTone.purple;
  }

  @override
  Widget build(BuildContext context) {
    final (gradient, borderColor) = switch (_tone) {
      _ChunkyButtonTone.blue => (
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7DD3FC), Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
          const Color(0xFF1259A7),
        ),
      _ChunkyButtonTone.coral => (
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFB38A), Color(0xFFFF7A45), Color(0xFFE85D2C)],
          ),
          const Color(0xFFC2410C),
        ),
      _ChunkyButtonTone.purple => (
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.purpleLight, AppTheme.purple],
          ),
          AppTheme.purpleDark,
        ),
    };

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(
            horizontal: 40,
            vertical: fontSize * 0.62,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(fontSize * 1.4),
            border: Border.all(color: borderColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.45),
                offset: const Offset(0, 6),
                blurRadius: 12,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -fontSize * 0.30,
                left: 8,
                right: 8,
                child: Container(
                  height: fontSize * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(fontSize),
                  ),
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.luckiestGuy(
                  color: Colors.white,
                  fontSize: fontSize,
                  height: 1.1,
                  shadows: const [
                    Shadow(color: Color(0x552D3561), offset: Offset(0, 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.stars, this.size = 20});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: filled ? AppTheme.warning : const Color(0xFFB9C0DE),
          size: size,
        );
      }),
    );
  }
}

/// Tilted ARROW CHALLENGE logo shared by splash and menu screens.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.04,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CartoonLogoText(
            'Endless',
            fontSize: 64,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE066), Color(0xFFFFB300)],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -14),
            child: const CartoonLogoText(
              'CHALLENGE',
              fontSize: 38,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFD9DCF0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cartoon logo text: gradient fill, thick purple outline, extruded shadow.
class CartoonLogoText extends StatelessWidget {
  const CartoonLogoText(
    this.text, {
    super.key,
    required this.fontSize,
    required this.gradient,
  });

  final String text;
  final double fontSize;
  final Gradient gradient;

  static const _outline = Color(0xFF3B1F5E);

  TextStyle _style({Paint? foreground, Color? color}) => GoogleFonts.luckiestGuy(
        fontSize: fontSize,
        height: 1.0,
        letterSpacing: 1,
        foreground: foreground,
        color: color,
      );

  @override
  Widget build(BuildContext context) {
    final strokeWidth = fontSize * 0.22;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(0, fontSize * 0.10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: _style(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..strokeJoin = StrokeJoin.round
                ..color = _outline.withValues(alpha: 0.9),
            ),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.center,
          style: _style(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = _outline,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: _style(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Glossy gradient loading bar used on the splash screen.
class SplashProgressBar extends StatelessWidget {
  const SplashProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x142D3561),
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fillW = constraints.maxWidth * clamped;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (fillW > 0)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: fillW,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppTheme.purpleLight,
                            AppTheme.purple,
                            Color(0xFF2196F3),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x448B3DFF),
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 2),
                          height: 5,
                          width: (fillW - 12).clamp(0, double.infinity),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(clamped * 100).round()}%',
          style: GoogleFonts.fredoka(
            color: AppTheme.navy.withValues(alpha: 0.55),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
