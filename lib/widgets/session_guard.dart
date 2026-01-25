import 'package:flutter/material.dart';
import '../services/session_manager.dart';

class SessionGuard extends StatelessWidget {
  final Widget child;
  const SessionGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SessionManager().resetActivity(),
      onPointerMove: (_) => SessionManager().resetActivity(),
      onPointerUp: (_) => SessionManager().resetActivity(),
      child: child,
    );
  }
}
