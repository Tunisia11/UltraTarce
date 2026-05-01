import 'package:flutter/material.dart';

import 'setup_mascot_area.dart';

/// Responsive shell for onboarding page 2.
///
/// Edit spacing between the form side and Tarek's mascot here. The setup logic
/// stays in `StoreSetupPage`; this file only decides where the visual pieces go.
class StoreSetupLayout extends StatelessWidget {
  const StoreSetupLayout({super.key, required this.content, this.topRoadmap});

  final Widget content;
  final Widget? topRoadmap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 920;
        final sidePadding = isWide ? 72.0 : 24.0;
        final roadmap = topRoadmap;

        return Padding(
          padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 4),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: roadmap == null
                    ? const SizedBox.shrink(key: ValueKey('empty-roadmap'))
                    : Padding(
                        key: const ValueKey('setup-roadmap'),
                        // This keeps the roadmap just under the logo, centered
                        // above the question/form area.
                        padding: const EdgeInsets.only(top: 2, bottom: 10),
                        child: Center(child: roadmap),
                      ),
              ),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: SingleChildScrollView(child: content),
                          ),
                          const SizedBox(width: 36),
                          const Expanded(
                            flex: 4,
                            child: SetupMascotArea(compact: false),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          const SizedBox(
                            height: 260,
                            child: SetupMascotArea(compact: true),
                          ),
                          const SizedBox(height: 16),
                          content,
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
