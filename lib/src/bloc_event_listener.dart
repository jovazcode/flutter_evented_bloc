import 'dart:async';

import 'package:evented_bloc/evented_bloc.dart';

import 'package:flutter/widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:provider/single_child_widget.dart';

/// Signature for the `listener` function which takes the `BuildContext` along
/// with the `event` and is responsible for executing when `events` are fired.
typedef EventedBlocWidgetListener<B extends EventStreamable<E>, E> = void
    Function(
  BuildContext context,
  B bloc,
  E event,
);

/// Signature for the `listenWhen` function which takes the fired `event`
/// and is responsible for returning a [bool] which determines whether
/// or not to call [EventedBlocWidgetListener] of [BlocEventListener]
/// with the fired `event`.
typedef EventedBlocListenerCondition<B extends EventStreamable<E>, E> = bool
    Function(B bloc, E event);

/// {@template bloc_event_listener}
/// Takes a [BlocEventListener] and an optional [bloc] and invokes
/// the [listener] when an `event` is fired from the [bloc].
/// It should be used for functionality that needs to occur only in response to
/// fired `events` such as navigation, showing a `SnackBar`, showing
/// a `Dialog`, etc...
///
/// If the [bloc] parameter is omitted, [BlocEventListener] will automatically
/// perform a lookup using [BlocProvider] and the current `BuildContext`.
///
/// ```dart
/// BlocEventListener<BlocA, BlocAEvent>(
///   listener: (context, bloc, event) {
///     // do stuff here based on BlocA's fired event
///   },
///   child: Container(),
/// )
/// ```
/// Only specify the [bloc] if you wish to provide a [bloc] that is otherwise
/// not accessible via [BlocProvider] and the current `BuildContext`.
///
/// ```dart
/// BlocEventListener<BlocA, BlocAEvent>(
///   value: blocA,
///   listener: (context, bloc, event) {
///     // do stuff here based on BlocA's fired event
///   },
///   child: Container(),
/// )
/// ```
/// {@endtemplate}
///
/// {@template bloc_event_listener_listen_when}
/// An optional [listenWhen] can be implemented for more granular control
/// over when [listener] is called.
/// [listenWhen] will be invoked on each [bloc] `event` fired.
/// [listenWhen] takes the fired `event` and must return a [bool] which
/// determines whether or not the [listener] function should be invoked.
/// [listenWhen] is optional and if omitted, it will default to `true`.
///
/// ```dart
/// BlocEventListener<BlocA, BlocAEvent>(
///   listenWhen: (bloc, event) {
///     // return true/false to determine whether or not
///     // to invoke listener with event
///   },
///   listener: (context, bloc event) {
///     // do stuff here based on BlocA's fired event
///   }
///   child: Container(),
/// )
/// ```
/// {@endtemplate}
class BlocEventListener<B extends EventStreamable<E>, E>
    extends BlocEventListenerBase<B, E> {
  /// {@macro bloc_event_listener}
  const BlocEventListener({
    required super.listener,
    super.key,
    super.bloc,
    super.listenWhen,
    super.child,
  }) : super();
}

/// {@template bloc_event_listener_base}
/// Base class for widgets that listen to events fired from a specified [bloc].
///
/// A [BlocEventListenerBase] is stateful and maintains the event subscription.
/// The type of the event and what happens with each fired event
/// is defined by sub-classes.
/// {@endtemplate}
abstract class BlocEventListenerBase<B extends EventStreamable<E>, E>
    extends SingleChildStatefulWidget {
  /// {@macro bloc_event_listener_base}
  const BlocEventListenerBase({
    required this.listener,
    super.key,
    this.bloc,
    super.child,
    this.listenWhen,
  });

  /// The [bloc] whose `state` will be listened to.
  /// Whenever the [bloc]'s `state` changes, [listener] will be invoked.
  final B? bloc;

  /// The [BlocWidgetListener] which will be called on every `state` change.
  /// This [listener] should be used for any code which needs to execute
  /// in response to a `state` change.
  final EventedBlocWidgetListener<B, E> listener;

  /// {@macro bloc_event_listener_listen_when}
  final EventedBlocListenerCondition<B, E>? listenWhen;

  @override
  SingleChildState<BlocEventListenerBase<B, E>> createState() =>
      _BlocEventListenerBaseState<B, E>();
}

class _BlocEventListenerBaseState<B extends EventStreamable<E>, E>
    extends SingleChildState<BlocEventListenerBase<B, E>> {
  StreamSubscription<E>? _subscription;
  // late EventStreamable<E> _bloc;
  late B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _subscribe();
  }

  @override
  void didUpdateWidget(BlocEventListenerBase<B, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<B>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      if (_subscription != null) {
        _unsubscribe();
        _bloc = currentBloc;
      }
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      if (_subscription != null) {
        _unsubscribe();
        _bloc = bloc;
      }
      _subscribe();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '''${widget.runtimeType} used outside of MultiBlocEventListener must specify a child.''',
    );
    if (widget.bloc == null) {
      // Trigger a rebuild if the bloc reference has changed.
      // See https://github.com/felangel/bloc/issues/2127.
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }
    return child!;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _bloc.eventStream.listen((event) {
      if (widget.listenWhen?.call(_bloc, event) ?? true) {
        widget.listener(context, _bloc, event);
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
