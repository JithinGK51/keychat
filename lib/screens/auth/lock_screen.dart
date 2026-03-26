import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import '../../providers/lock_provider.dart';
import '../../utils/theme.dart';
import '../../utils/notification_helper.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _input = "";

  void _onKeyTap(String value) {
    if (_input.length < 4) {
      setState(() => _input += value);
      if (_input.length == 4) {
        ref.read(lockProvider.notifier).unlock(_input);
        if (ref.read(lockProvider).isLocked) {
          // Wrong PIN
          NotificationHelper.error(context, 'Incorrect PIN');
          setState(() => _input = "");
        }
      }
    }
  }

  void _onDelete() {
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.card],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HeroIcon(HeroIcons.lockClosed, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text('Enter PIN to Unlock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _input.length ? AppColors.primary : Colors.white24,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 64),
              _buildNumberPad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((char) => _NumberButton(label: char, onTap: () => _onKeyTap(char))).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 80),
              _NumberButton(label: '0', onTap: () => _onKeyTap('0')),
              IconButton(
                onPressed: _onDelete,
                icon: const HeroIcon(HeroIcons.backspace, size: 32, color: Colors.white70),
                style: IconButton.styleFrom(fixedSize: const Size(80, 80)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NumberButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(label, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
