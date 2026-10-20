import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'widgets/desktop_navigation_rail.dart';
import 'widgets/desktop_player_bar.dart';
import 'widgets/desktop_shortcuts_handler.dart';
import 'widgets/desktop_sidebar.dart';

class DesktopAppShell extends StatelessWidget {
  final String currentPath;
  final Widget child;

  const DesktopAppShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopShortcutsHandler(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width < Responsive.mobileBreakpoint) {
            return child;
          }

          if (width <= Responsive.tabletBreakpoint) {
            return Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        DesktopNavigationRail(currentPath: currentPath),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                  const DesktopPlayerBar(),
                ],
              ),
            );
          }

          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      DesktopSidebar(currentPath: currentPath),
                      Expanded(child: child),
                    ],
                  ),
                ),
                const DesktopPlayerBar(),
              ],
            ),
          );
        },
      ),
    );
  }
}
