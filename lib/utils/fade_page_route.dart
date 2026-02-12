import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final RouteSettings settings;

  FadePageRoute({
    required this.page,
    required this.settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Smooth fade with subtle scale effect
            var fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );

            var scaleAnimation = Tween<double>(
              begin: 0.98,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}
