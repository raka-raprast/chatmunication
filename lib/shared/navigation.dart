import 'package:flutter/material.dart';

/// App-wide navigator key, used by anything that needs to push routes or
/// reach the root `Overlay` without a `BuildContext` on hand — e.g.
/// notification taps and the in-app message banner.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
