import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/couple_service.dart';

class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      helpText: 'Pick upcoming event date',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addEvent(String coupleId) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(eventServiceProvider).addEvent(coupleId, title, _selectedDate!);
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      _titleController.clear();
      setState(() {
        _selectedDate = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('💖 Added "$title" countdown!'), backgroundColor: LoveSnapsColors.pinkAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddEventBottomSheet(String coupleId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: LoveSnapsColors.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '🎉 Add Upcoming Event',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: LoveSnapsColors.primary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'e.g. Next Visit ✈️, Anniversary 💖',
                ),
                maxLength: 30,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDate == null
                      ? 'No date selected'
                      : 'Date: ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                ),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Pick Date'),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now.add(const Duration(days: 1)),
                      firstDate: now,
                      lastDate: DateTime(now.year + 5),
                    );
                    if (picked != null) {
                      setModalState(() {
                        _selectedDate = picked;
                      });
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : () => _addEvent(coupleId),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Countdown 💕'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final couple = ref.watch(coupleStreamProvider).value;
    final eventsAsync = ref.watch(eventsStreamProvider);

    if (couple == null) {
      return const Scaffold(body: Center(child: Text('Pair first to see events.')));
    }

    final cardColors = [
      const Color(0xFFF5F3FF), // Lavender
      const Color(0xFFFEF2F2), // Pink
      const Color(0xFFECFDF5), // Mint
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎉 Our Countdowns'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: LoveSnapsColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, size: 28),
            onPressed: () => _showAddEventBottomSheet(couple.coupleId),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⏳', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 24),
                    Text(
                      'No events planned!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: LoveSnapsColors.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add next visit, anniversary, dates, or trips to count down together!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => _showAddEventBottomSheet(couple.coupleId),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
                      child: const Text('Create Event 🎉'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final days = event.daysRemaining;
              final color = cardColors[index % cardColors.length];

              return Card(
                color: color,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: LoveSnapsColors.primary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(event.date),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Days remaining chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              days <= 0 ? '🎉' : '$days',
                              style: TextStyle(
                                fontSize: days <= 0 ? 22 : 24,
                                fontWeight: FontWeight.extrabold,
                                color: LoveSnapsColors.pinkAccent,
                              ),
                            ),
                            Text(
                              days <= 0 ? 'Today!' : 'days left',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Event?'),
                              content: const Text('Are you sure you want to delete this event?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(eventServiceProvider).deleteEvent(couple.coupleId, event.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load events: $err')),
      ),
    );
  }
}
