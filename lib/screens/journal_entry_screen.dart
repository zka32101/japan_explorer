import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../widgets/cached_image.dart';

// ── Write / Edit screen ───────────────────────────────────────────────────────

class WriteJournalScreen extends ConsumerStatefulWidget {
  final String curationId;
  final String curationTitle;
  final String? existingEntryId;

  const WriteJournalScreen({
    super.key,
    required this.curationId,
    required this.curationTitle,
    this.existingEntryId,
  });

  @override
  ConsumerState<WriteJournalScreen> createState() => _WriteJournalScreenState();
}

class _WriteJournalScreenState extends ConsumerState<WriteJournalScreen> {
  final _contentCtrl = TextEditingController();
  JournalMood _mood = JournalMood.good;
  DateTime _visitDate = DateTime.now();
  File? _imageFile;
  bool _isSaving = false;

  JournalEntry? get _existing {
    if (widget.existingEntryId == null) return null;
    return ref
        .read(journalProvider)
        .entries
        .where((e) => e.id == widget.existingEntryId)
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    final entry = _existing;
    if (entry != null) {
      _contentCtrl.text = entry.content;
      _mood = entry.mood;
      _visitDate = entry.visitDate;
    }
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('journal.content_required'))));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(journalProvider.notifier);
      if (widget.existingEntryId != null) {
        await notifier.updateEntry(
          widget.existingEntryId!,
          content: _contentCtrl.text.trim(),
          mood: _mood,
          visitDate: _visitDate,
        );
      } else {
        await notifier.createEntry(
          curationId: widget.curationId,
          curationTitle: widget.curationTitle,
          content: _contentCtrl.text.trim(),
          mood: _mood,
          visitDate: _visitDate,
          imageFile: _imageFile,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('errors.generic'))));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntryId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? tr('journal.edit_title')
            : tr('journal.write_title')),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(tr('common.save'),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Spot name
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.curationTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mood selector
          Text(tr('journal.mood'),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: JournalMood.values
                .map((m) => _MoodChip(
                      mood: m,
                      selected: _mood == m,
                      onTap: () => setState(() => _mood = m),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Visit date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined,
                color: AppColors.primary),
            title: Text(tr('journal.visit_date')),
            subtitle: Text(_formatDate(_visitDate)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _visitDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _visitDate = picked);
            },
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Photo
          if (!isEditing) ...[
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(12),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              size: 36,
                              color: AppColors.textSecondary),
                          const SizedBox(height: 6),
                          Text(tr('journal.add_photo'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Content
          Text(tr('journal.your_notes'),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _contentCtrl,
            maxLines: 8,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText: tr('journal.content_hint'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}

// ── Mood chip ─────────────────────────────────────────────────────────────────

class _MoodChip extends StatelessWidget {
  final JournalMood mood;
  final bool selected;
  final VoidCallback onTap;
  const _MoodChip(
      {required this.mood,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(mood.label,
                style: TextStyle(
                    fontSize: 10,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ── View screen (read-only with edit/delete options) ─────────────────────────

class JournalEntryScreen extends ConsumerWidget {
  final String entryId;
  const JournalEntryScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref
        .watch(journalProvider)
        .entries
        .where((e) => e.id == entryId)
        .firstOrNull;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Entry not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('journal.entry_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: tr('common.edit'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WriteJournalScreen(
                  curationId: entry.curationId,
                  curationTitle: entry.curationTitle,
                  existingEntryId: entry.id,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: tr('common.delete'),
            onPressed: () => _confirmDelete(context, ref, entry),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (entry.imageUrl.isNotEmpty)
            CachedImage(url: entry.imageUrl, height: 220, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Text(entry.mood.emoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.curationTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          Text(
                            '${entry.mood.label} · ${_formatDate(entry.visitDate)}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                // Content
                Text(entry.content,
                    style: const TextStyle(
                        fontSize: 16, height: 1.7)),
                const SizedBox(height: 40),
                // Footer
                Text(
                  '${tr('journal.written')} ${_formatDate(entry.createdAt)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, JournalEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('journal.delete_title')),
        content: Text(tr('journal.delete_confirm')),
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
    if (ok == true && context.mounted) {
      await ref.read(journalProvider.notifier).deleteEntry(entry.id);
      Navigator.pop(context);
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}
