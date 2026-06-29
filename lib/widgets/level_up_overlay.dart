import 'package:flutter/material.dart';
import '../models/user.dart';
import '../config/theme.dart';

/// Full-screen animated overlay shown when the user levels up.
/// Wrap your screen body in a [Stack] and show this on top when
/// [ChallengeState.leveledUp] (or [CameraState.leveledUp]) is true.
class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _starCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _starRotate;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _starCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeIn);
    _starRotate = Tween<double>(begin: 0, end: 1).animate(_starCtrl);

    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  String get _title => _levelTitle(widget.newLevel);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rotating star ring
                    RotationTransition(
                      turns: _starRotate,
                      child: const Text('✨', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(height: 12),
                    // "LEVEL UP!" label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Level number
                    Text(
                      'Lv.${widget.newLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Keep exploring Japan!',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 28),
                    // Stars decoration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.newLevel.clamp(1, 10),
                        (i) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Text('⭐', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(160, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                      child: const Text('Awesome! 🎉',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _levelTitle(int level) {
    // Mirrors AppUser.levelTitle
    switch (level) {
      case 2: return 'Tourist+';
      case 3: return 'Traveler';
      case 4: return 'Traveler+';
      case 5: return 'Explorer';
      case 6: return 'Explorer+';
      case 7: return 'Cultural Ambassador';
      case 8: return 'Cultural Ambassador+';
      case 9: return 'Japan Expert';
      case 10: return 'Japan Master';
      default: return 'Tourist';
    }
  }
}
