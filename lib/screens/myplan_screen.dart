import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../config/theme.dart';
import '../models/rating.dart';
import '../providers/plan_provider.dart';

class MyPlanScreen extends ConsumerWidget {
  const MyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(planNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('myplan.title')),
        actions: [
          IconButton(
            icon: const Text('✨', style: TextStyle(fontSize: 18)),
            tooltip: tr('myplan.generate_with_ai'),
            onPressed: () => context.push('/ai-planner'),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: tr('myplan.view_on_map'),
            onPressed: () => context.go('/map'),
          ),
        ],
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(tr('myplan.error_prefix', args: ['$e']))),
        data: (plans) => plans.isEmpty
            ? _buildEmpty(context)
            : _buildPlanList(context, ref, plans),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(tr('myplan.new_plan')),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map_outlined,
                size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(tr('myplan.no_plans_title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('myplan.no_plans_subtitle'),
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context, null),
            icon: const Icon(Icons.add),
            label: Text(tr('myplan.create_first_plan')),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/ai-planner'),
            icon: const Text('✨', style: TextStyle(fontSize: 16)),
            label: Text(tr('myplan.generate_with_ai')),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList(
      BuildContext context, WidgetRef ref, List<Plan> plans) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PlanCard(
        plan: plans[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PlanDetailScreen(plan: plans[i])),
        ),
        onDelete: () =>
            _deletePlan(context, ref, plans[i].id, plans[i].title),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef? ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('myplan.create_new_plan'),
                  style: const
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: tr('myplan.plan_name_label'),
                  hintText: tr('myplan.plan_name_hint'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  await ref
                      .read(planNotifierProvider.notifier)
                      .createPlan(ctrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(tr('myplan.create')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePlan(BuildContext context, WidgetRef ref,
      String planId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('myplan.delete_plan_title')),
        content: Text(tr('myplan.delete_plan_confirm', args: [title])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('common.cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('common.delete'),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(planNotifierProvider.notifier).deletePlan(planId);
    }
  }
}

// ── プランカード ──────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlanCard(
      {required this.plan, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.map,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                            tr('myplan.spots_count',
                                args: ['${plan.spots.length}']),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          const Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(tr('common.delete'),
                              style: const TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              if (plan.spots.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...plan.spots.take(3).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${s.order + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.curationTitle,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    )),
                if (plan.spots.length > 3)
                  Text(
                      tr('myplan.more_spots',
                          args: ['${plan.spots.length - 3}']),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── プラン詳細 ──────────────────────────────────────────────────
class PlanDetailScreen extends ConsumerStatefulWidget {
  final Plan plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  late List<PlanSpot> _spots;

  @override
  void initState() {
    super.initState();
    _spots = List.from(widget.plan.spots)
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.title),
        actions: [
          IconButton(
              icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: _spots.isEmpty
          ? _buildEmptyPlan(context)
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _spots.length,
              onReorder: _onReorder,
              itemBuilder: (_, i) => _SpotTile(
                key: ValueKey(_spots[i].curationId),
                spot: _spots[i],
                index: i,
                onDelete: () => _removeSpot(i),
                onTap: () =>
                    context.go('/home/detail/${_spots[i].curationId}'),
              ),
            ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildEmptyPlan(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_location_alt_outlined,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(tr('myplan.no_spots_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(tr('myplan.no_spots_subtitle'),
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            icon: const Icon(Icons.explore),
            label: Text(tr('myplan.explore_spots')),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              icon: const Icon(Icons.add_location_alt),
              label: Text(tr('myplan.add_spots')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _spots.isEmpty
                  ? null
                  : () => context.go('/map'),
              icon: const Icon(Icons.map),
              label: Text(tr('myplan.view_on_map')),
            ),
          ),
        ],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final spot = _spots.removeAt(oldIndex);
      _spots.insert(newIndex, spot);
      for (var i = 0; i < _spots.length; i++) {
        _spots[i] = _spots[i].copyWith(order: i);
      }
    });
  }

  void _removeSpot(int index) {
    setState(() {
      _spots.removeAt(index);
      for (var i = 0; i < _spots.length; i++) {
        _spots[i] = _spots[i].copyWith(order: i);
      }
    });
  }
}

// ── スポットタイル ──────────────────────────────────────────────────
class _SpotTile extends StatelessWidget {
  final PlanSpot spot;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SpotTile({
    super.key,
    required this.spot,
    required this.index,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        title: Text(spot.curationTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: spot.note != null
            ? Text(spot.note!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                onPressed: onTap),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.red, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
