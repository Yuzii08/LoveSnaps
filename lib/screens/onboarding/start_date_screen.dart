import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';

class StartDateScreen extends ConsumerStatefulWidget {
  const StartDateScreen({super.key});

  @override
  ConsumerState<StartDateScreen> createState() => _StartDateScreenState();
}

class _StartDateScreenState extends ConsumerState<StartDateScreen> {
  DateTime? _selectedDate;
  bool _loading = false;
  String? _error;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'When did your relationship start?',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: LoveSnapsColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() { _selectedDate = picked; });
    }
  }

  Future<void> _confirm() async {
    if (_selectedDate == null) {
      setState(() { _error = 'Please select your relationship start date.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final userDoc = await ref.read(currentUserDocProvider.future);
      final coupleId = userDoc?.coupleId;
      if (coupleId == null) throw Exception('Not paired yet.');
      await ref.read(coupleServiceProvider).setStartDate(coupleId, _selectedDate!);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/permissions');
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysCount = _selectedDate != null
        ? DateTime.now().difference(_selectedDate!).inDays + 1
        : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📅', style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'When did your\nlove begin?',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your relationship anniversary date. You can always change it later.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: LoveSnapsColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 48),

              // Date picker card
              GestureDetector(
                onTap: _pickDate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedDate != null
                          ? [LoveSnapsColors.primaryContainer, LoveSnapsColors.tertiaryContainer.withOpacity(0.3)]
                          : [LoveSnapsColors.surface, LoveSnapsColors.surfaceVariant],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _selectedDate != null
                          ? LoveSnapsColors.primary
                          : LoveSnapsColors.onSurfaceVariant.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
                            : 'Tap to select date',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: _selectedDate != null
                                  ? LoveSnapsColors.onSurface
                                  : LoveSnapsColors.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      if (daysCount != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: LoveSnapsColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '✨ Day $daysCount together',
                            style: TextStyle(
                              color: LoveSnapsColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.95, 0.95), end: const Offset(1, 1),
                  ),

              const SizedBox(height: 16),

              Center(
                child: TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar_rounded),
                  label: const Text('Change date'),
                  style: TextButton.styleFrom(
                    foregroundColor: LoveSnapsColors.primary,
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LoveSnapsColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: LoveSnapsColors.error)),
                ),
              ],

              const Spacer(),

              ElevatedButton(
                onPressed: _loading ? null : _confirm,
                child: _loading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Our Anniversary 💕'),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/permissions'),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: LoveSnapsColors.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
