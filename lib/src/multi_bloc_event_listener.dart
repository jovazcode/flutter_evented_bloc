import 'package:flutter/widgets.dart';

import 'package:flutter_evented_bloc/src/bloc_event_listener.dart';

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// {@template multi_bloc_event_listener}
/// Merges multiple [BlocEventListener] widgets into one widget tree.
///
/// [MultiBlocEventListener] improves the readability and eliminates the need
/// to nest multiple [BlocEventListener]s.
///
/// By using [MultiBlocEventListener] we can go from:
///
/// ```dart
/// BlocEventListener<BlocA, BlocAEvent>(
///   listener: (context, bloc, event) {},
///   child: BlocEventListener<BlocB, BlocBEvent>(
///     listener: (context, bloc, event) {},
///     child: BlocEventListener<BlocC, BlocCEvent>(
///       listener: (context, bloc, event) {},
///       child: ChildA(),
///     ),
///   ),
/// )
/// ```
///
/// to:
///
/// ```dart
/// MultiBlocEventListener(
///   listeners: [
///     BlocEventListener<BlocA, BlocAEvent>(
///       listener: (context, bloc, event) {},
///     ),
///     BlocEventListener<BlocB, BlocBEvent>(
///       listener: (context, bloc, event) {},
///     ),
///     BlocEventListener<BlocC, BlocCEvent>(
///       listener: (context, bloc, event) {},
///     ),
///   ],
///   child: ChildA(),
/// )
/// ```
///
/// [MultiBlocEventListener] converts the [BlocEventListener] list into
/// a tree of nested [BlocEventListener] widgets.
/// As a result, the only advantage of using [MultiBlocEventListener]
/// is improved readability due to the reduction in nesting and boilerplate.
/// {@endtemplate}
class MultiBlocEventListener extends MultiProvider {
  /// {@macro multi_bloc_event_listener}
  MultiBlocEventListener({
    required List<SingleChildWidget> listeners,
    required Widget super.child,
    super.key,
  }) : super(providers: listeners);
}
