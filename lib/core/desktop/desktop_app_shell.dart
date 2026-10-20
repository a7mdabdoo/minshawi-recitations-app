import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'widgets/desktop_navigation_rail.dart';
import 'widgets/desktop_player_bar.dart';
import 'widgets/desktop_shortcuts_handler.dart';
import 'widgets/desktop_sidebar.dart';

class DesktopAppShell extends StatefulWidget {
  final String currentPath;
  final Widget child;

  const DesktopAppShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  @override
  State<DesktopAppShell> createState() => _DesktopAppShellState();
}

class _DesktopAppShellState extends State<DesktopAppShell> {
  bool _isSidebarCollapsed = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPlayerPage = widget.currentPath == '/player';

    return DesktopShortcutsHandler(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width < Responsive.mobileBreakpoint) {
            return widget.child;
          }

          if (width <= Responsive.tabletBreakpoint) {
            return Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        DesktopNavigationRail(currentPath: widget.currentPath),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                  if (!isPlayerPage) const DesktopPlayerBar(),
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
                      DesktopSidebar(
                        currentPath: widget.currentPath,
                        isCollapsed: _isSidebarCollapsed,
                        onToggleCollapse: _toggleSidebar,
                      ),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
                if (!isPlayerPage) const DesktopPlayerBar(),
              ],
            ),
          );
        },
      ),
    );
  }
}
