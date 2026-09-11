import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/referral_provider.dart';
import '../services/share_service.dart';
import '../utils/constants.dart';

class InviteFriendsScreen extends ConsumerWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeAsync = ref.watch(myReferralCodeProvider);
    final countAsync = ref.watch(referralCountProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('referral.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.card_giftcard, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              tr('referral.subtitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              tr('referral.bonus_note',
                  args: ['${AppConstants.xpReferralBonus}']),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Code card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    tr('referral.your_code'),
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  codeAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text(tr('common.error')),
                    data: (code) => Text(
                      code ?? '—',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: codeAsync.value == null
                              ? null
                              : () {
                                  Clipboard.setData(
                                      ClipboardData(text: codeAsync.value!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text(tr('referral.copied'))),
                                  );
                                },
                          icon: const Icon(Icons.copy, size: 18),
                          label: Text(tr('referral.copy')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: codeAsync.value == null
                              ? null
                              : () => shareService
                                  .shareReferralCode(codeAsync.value!),
                          icon: const Icon(Icons.share, size: 18),
                          label: Text(tr('referral.share')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            countAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (count) => count > 0
                  ? Text(
                      tr('referral.invited_count', args: ['$count']),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            Text(
              tr('referral.have_code'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const _RedeemCodeField(),
          ],
        ),
      ),
    );
  }
}

class _RedeemCodeField extends ConsumerStatefulWidget {
  const _RedeemCodeField();

  @override
  ConsumerState<_RedeemCodeField> createState() => _RedeemCodeFieldState();
}

class _RedeemCodeFieldState extends ConsumerState<_RedeemCodeField> {
  final _ctrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    final result = await ref
        .read(referralNotifierProvider.notifier)
        .redeemCode(_ctrl.text);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final messageKey = switch (result) {
      RedeemResult.success => 'referral.redeem_success',
      RedeemResult.invalidCode => 'referral.redeem_invalid',
      RedeemResult.selfReferral => 'referral.redeem_self',
      RedeemResult.alreadyRedeemed => 'referral.redeem_used',
      RedeemResult.error => 'common.error',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(messageKey))),
    );
    if (result == RedeemResult.success) _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: tr('referral.code_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: _isSubmitting ? null : _redeem,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr('referral.redeem')),
        ),
      ],
    );
  }
}
