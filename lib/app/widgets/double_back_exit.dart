import 'package:flutter/material.dart';

class DoubleBackExit extends StatefulWidget {
  final Widget child;
  const DoubleBackExit({super.key, required this.child});

  @override
  State<DoubleBackExit> createState() => _DoubleBackExitState();
}

class _DoubleBackExitState extends State<DoubleBackExit> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    // We use WillPopScope for backward compatibility and simpler logic for exiting the app.
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        final maxDuration = const Duration(seconds: 2);
        final isWarning = _lastPressedAt == null ||
            now.difference(_lastPressedAt!) > maxDuration;

        if (isWarning) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false; // Prevent pop
        }

        return true; // Allow pop (exit app)
      },
      child: widget.child,
    );
  }
}
