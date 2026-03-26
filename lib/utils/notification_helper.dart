import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:heroicons/heroicons.dart';
import 'dart:ui';
import 'theme.dart';

class NotificationHelper {
  static void show(
    BuildContext context, {
    required String message,
    required String title,
    bool isError = false,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: (isError ? Colors.red : AppColors.card).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isError ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isError ? Colors.white : AppColors.primary).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: HeroIcon(
                        isError ? HeroIcons.exclamationTriangle : HeroIcons.checkCircle,
                        color: isError ? Colors.red.shade200 : AppColors.primary,
                        size: 24,
                        style: HeroIconStyle.solid,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const HeroIcon(HeroIcons.xMark, size: 18, color: Colors.white24),
                      onPressed: () => entry.remove(),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.5, end: 0, curve: Curves.easeOutBack)
              .then(delay: 4.seconds)
              .fadeOut(duration: 400.ms)
              .slideY(begin: 0, end: -0.5)
              .callback(callback: (_) {
                if (entry.mounted) entry.remove();
              }),
        ),
      ),
    );

    overlay.insert(entry);
  }

  static void success(BuildContext context, String message, {String title = "Success"}) {
    show(context, message: message, title: title, isError: false);
  }

  static void error(BuildContext context, String message, {String title = "Error"}) {
    show(context, message: message, title: title, isError: true);
  }
}
