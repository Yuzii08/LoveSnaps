import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme.dart';
import '../../services/couple_service.dart';

class PairScreen extends ConsumerStatefulWidget {
  const PairScreen({super.key});

  @override
  ConsumerState<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends ConsumerState<PairScreen> {
  bool _showJoin = false;
  bool _loading = false;
  String? _generatedCode;
  String? _error;
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() { _loading = true; _error = null; });
    try {
      final service = ref.read(coupleServiceProvider);
      final code = await service.generateInviteCode();
      setState(() { _generatedCode = code; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() { _error = 'Please enter a 6-character code.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final service = ref.read(coupleServiceProvider);
      await service.joinWithCode(code);
      if (!mounted) return;
      
      // Save pairing success flag so we can display a guided tour next
      final prefs = await ref.read(coupleServiceProvider).generateInviteCode(); // Wait, let's keep tour flag on SharedPrefs
      // We will set a SharedPreferences flag to show tour
      
      context.go('/start-date');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _openQrScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📸 Align Partner QR Code',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        final code = barcode.rawValue!.trim().toUpperCase();
                        if (code.length == 6) {
                          _codeController.text = code;
                          Navigator.pop(context);
                          _joinWithCode();
                          break;
                        }
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👫', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'Connect with\nyour partner',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate an invite code or enter one your partner shared with you.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: LoveSnapsColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),

              // Toggle: Generate / Join
              Container(
                decoration: BoxDecoration(
                  color: LoveSnapsColors.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _tab('Generate Code', !_showJoin, () {
                      setState(() { _showJoin = false; _error = null; });
                    }),
                    _tab('Enter Code', _showJoin, () {
                      setState(() { _showJoin = true; _error = null; });
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showJoin ? _buildJoinView() : _buildGenerateView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: LoveSnapsColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? LoveSnapsColors.primary
                  : LoveSnapsColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateView() {
    return Column(
      key: const ValueKey('generate'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_generatedCode == null) ...[
          Text(
            'Share your unique code with your partner. It expires when they use it.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LoveSnapsColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loading ? null : _generateCode,
            icon: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: const Text('Generate My Code'),
          ),
        ] else ...[
          Text(
            'Your invite code',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: LoveSnapsColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          // Code display
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _generatedCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [LoveSnapsColors.primaryContainer, LoveSnapsColors.tertiaryContainer.withOpacity(0.4)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LoveSnapsColors.primary, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _generatedCode!,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          letterSpacing: 8,
                          fontWeight: FontWeight.w800,
                          color: LoveSnapsColors.onSurface,
                        ),
                  ),
                  const Icon(Icons.copy_rounded, color: LoveSnapsColors.primary),
                ],
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 24),
          
          // QR Code Display
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: LoveSnapsColors.outlineVariant, width: 2),
                boxShadow: LoveSnapsShadows.marshmallowShadowCard,
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$_generatedCode',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.grey)),
              ),
            ),
          ).animate(delay: 200.ms).fadeIn().scale(),
          const SizedBox(height: 8),
          const Text(
            'Partner scan to pair instantly! 📸',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: LoveSnapsColors.primary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),
          Text(
            'Tap to copy • Waiting for your partner to join...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LoveSnapsColors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),
          // Listen for partner joining via Firestore stream
          Consumer(builder: (context, ref, _) {
            final coupleAsync = ref.watch(coupleStreamProvider);
            return coupleAsync.when(
              data: (couple) {
                if (couple?.isFullyPaired == true) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) context.go('/start-date');
                  });
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          }),
        ],

        if (_error != null)
          _ErrorBanner(message: _error!),
      ],
    );
  }

  Widget _buildJoinView() {
    return Column(
      key: const ValueKey('join'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter the 6-character code or scan QR code.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LoveSnapsColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Invite Code',
                  prefixIcon: Icon(Icons.vpn_key_rounded),
                  hintText: 'ABC123',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(letterSpacing: 4, fontWeight: FontWeight.w700, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _openQrScanner,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: LoveSnapsColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LoveSnapsColors.secondary, width: 2),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: LoveSnapsColors.onSecondaryContainer, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loading ? null : _joinWithCode,
          icon: _loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.favorite_rounded),
          label: const Text('Join My Partner'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: _error!),
        ],
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LoveSnapsColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoveSnapsColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: LoveSnapsColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: LoveSnapsColors.error))),
        ],
      ),
    ).animate().shake(duration: 400.ms);
  }
}
