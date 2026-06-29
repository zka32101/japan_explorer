import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/curation.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../services/firebase_service.dart';

// ─── Main screen ──────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    final notifier = ref.read(onboardingProvider.notifier);
    final state = ref.read(onboardingProvider);
    notifier.nextStep();
    _animateToPage(state.step + 1);
  }

  void _back() {
    final notifier = ref.read(onboardingProvider.notifier);
    final state = ref.read(onboardingProvider);
    notifier.prevStep();
    _animateToPage(state.step - 1);
  }

  Future<void> _complete() async {
    final user = ref.read(appUserProvider).valueOrNull;
    await ref.read(onboardingProvider.notifier).complete(
      savePreferences: (interests) async {
        if (user != null) {
          await ref
              .read(firebaseServiceProvider)
              .updateUserPreferences(user.uid, interests);
        }
      },
    );
    // onboardingStatusProvider is now true → GoRouter redirects to /home
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header: back button + step indicator ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (state.step > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: _back,
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: _StepIndicator(
                          current: state.step, total: 5),
                    ),
                    // Skip (steps 0-3 only)
                    if (state.step < 4)
                      TextButton(
                        onPressed: _complete,
                        child: Text(
                          tr('common.skip'),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Page content ──
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _Step0Language(),
                    _Step1Interests(),
                    _Step2TravelStyle(),
                    _Step3Notifications(),
                    _Step4Complete(),
                  ],
                ),
              ),

              // ── Bottom CTA ──
              _BottomNav(
                step: state.step,
                onNext: _next,
                onComplete: _complete,
                isSaving: state.isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isDone = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone || isActive
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Bottom navigation ────────────────────────────────────────────────────────

class _BottomNav extends ConsumerWidget {
  final int step;
  final VoidCallback onNext;
  final Future<void> Function() onComplete;
  final bool isSaving;

  const _BottomNav({
    required this.step,
    required this.onNext,
    required this.onComplete,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    bool canProceed;
    switch (step) {
      case 1:
        canProceed = state.canProceedFromStep1;
      case 2:
        canProceed = state.canProceedFromStep2;
      default:
        canProceed = true;
    }

    // Step 4 has its own CTA inside the page
    if (step == 4) return const SizedBox.shrink();

    // Step 3 (notifications) has its own buttons
    if (step == 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (canProceed && !isSaving) ? onNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: isSaving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr('common.next'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Step 0: Language selection ───────────────────────────────────────────────

class _Step0Language extends ConsumerWidget {
  const _Step0Language();

  static const _languages = [
    ('en', '🇺🇸', 'English', 'English'),
    ('ja', '🇯🇵', '日本語', 'Japanese'),
    ('zh', '🇨🇳', '中文', 'Chinese'),
    ('ko', '🇰🇷', '한국어', 'Korean'),
    ('fr', '🇫🇷', 'Français', 'French'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).language;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Center(
            child: Text('🗾', style: TextStyle(fontSize: 72)),
          ),
          const SizedBox(height: 20),
          Text(
            tr('onboarding.step0.title'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('onboarding.step0.subtitle'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: _languages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final (code, flag, native, english) = _languages[i];
                final isSelected = selected == code;
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .setLanguage(code);
                    context.setLocale(Locale(code));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(flag,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              native,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                              ),
                            ),
                            Text(
                              english,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Interests ────────────────────────────────────────────────────────

class _Step1Interests extends ConsumerWidget {
  const _Step1Interests();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ref.watch(onboardingProvider).interests;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            tr('onboarding.step1.title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('onboarding.step1.subtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: CurationCategory.all.length,
              itemBuilder: (context, index) {
                final cat = CurationCategory.all[index];
                final isSelected = interests.contains(cat);
                return _InterestTile(
                  category: cat,
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(onboardingProvider.notifier)
                      .toggleInterest(cat),
                );
              },
            ),
          ),
          if (interests.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Center(
                child: Text(
                  tr('onboarding.step1.hint'),
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InterestTile extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestTile(
      {required this.category,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(CurationCategory.emoji(category),
                style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(
              tr('category.$category'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Travel style ──────────────────────────────────────────────────────

class _Step2TravelStyle extends ConsumerWidget {
  const _Step2TravelStyle();

  static const _styles = [
    ('solo', '🧳', 'solo'),
    ('couple', '💑', 'couple'),
    ('family', '👨‍👩‍👧', 'family'),
    ('group', '👥', 'group'),
  ];

  static const _durations = [
    ('weekend', 'weekend'),
    ('one_week', 'one_week'),
    ('two_weeks', 'two_weeks'),
    ('month_plus', 'month_plus'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            tr('onboarding.step2.title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('onboarding.step2.subtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),

          // Travel style
          Text(
            tr('onboarding.step2.style_label'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _styles.map((s) {
              final (key, emoji, _) = s;
              final isSelected = state.travelStyle == key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref
                      .read(onboardingProvider.notifier)
                      .setTravelStyle(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: isSelected ? 0 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(
                          tr('onboarding.step2.$key'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Trip duration
          Text(
            tr('onboarding.step2.duration_label'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _durations.map((d) {
              final (key, _) = d;
              final isSelected = state.tripDuration == key;
              return GestureDetector(
                onTap: () => ref
                    .read(onboardingProvider.notifier)
                    .setTripDuration(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    tr('onboarding.step2.$key'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Step 3: Notifications ────────────────────────────────────────────────────

class _Step3Notifications extends StatefulWidget {
  const _Step3Notifications();

  @override
  State<_Step3Notifications> createState() => _Step3NotificationsState();
}

class _Step3NotificationsState extends State<_Step3Notifications>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bellCtrl;
  late final Animation<double> _bellAnim;

  static const _features = [
    ('challenge', Icons.emoji_events_outlined),
    ('streak', Icons.local_fire_department_outlined),
    ('events', Icons.event_outlined),
    ('meetup', Icons.people_outline),
  ];

  @override
  void initState() {
    super.initState();
    _bellCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bellAnim = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _bellCtrl, curve: Curves.elasticIn),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _bellCtrl.repeat(reverse: true, period: const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _bellCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestPermission(BuildContext context) async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (context.mounted) _goNext(context);
  }

  void _goNext(BuildContext context) {
    // Propagate to parent — find the OnboardingScreen state
    final state =
        context.findAncestorStateOfType<_OnboardingScreenState>();
    state?._next();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: RotationTransition(
              turns: _bellAnim,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_outlined,
                    size: 44, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('onboarding.step3.title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('onboarding.step3.subtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 28),

          // Feature list
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(f.$2, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      tr('onboarding.step3.${f.$1}'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Allow button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _requestPermission(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                tr('onboarding.step3.allow'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _goNext(context),
              child: Text(
                tr('onboarding.step3.later'),
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Step 4: Complete ─────────────────────────────────────────────────────────

class _Step4Complete extends StatefulWidget {
  const _Step4Complete();

  @override
  State<_Step4Complete> createState() => _Step4CompleteState();
}

class _Step4CompleteState extends State<_Step4Complete>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isSaving = ref.watch(onboardingProvider).isSaving;
        final screen =
            context.findAncestorStateOfType<_OnboardingScreenState>();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎉', style: TextStyle(fontSize: 52)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      tr('onboarding.step4.title'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr('onboarding.step4.subtitle'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () => screen?._complete(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tr('onboarding.step4.cta'),
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('🗾',
                                      style: TextStyle(fontSize: 20)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
