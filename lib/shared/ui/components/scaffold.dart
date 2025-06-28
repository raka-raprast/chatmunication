import 'package:chatmunication/shared/theme/colors.dart';
import 'package:flutter/material.dart';

class CMScaffold extends StatelessWidget {
  const CMScaffold({super.key, this.appBar, this.body});
  final PreferredSizeWidget? appBar;
  final Widget? body;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: CMColors.background,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
              CMColors.primary.withValues(alpha: 0.1),
              CMColors.primaryVariant.withValues(alpha: 0.15),
            ])),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            body: body,
          ),
        ],
      ),
    );
  }
}
