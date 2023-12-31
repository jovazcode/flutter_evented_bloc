import 'package:flutter/material.dart';
import 'package:flutter_evented_bloc/flutter_evented_bloc.dart';

/// {@template bloc_event_consumer}
/// [BlocEventConsumer] exposes a [builder] and [listener] in order to react
/// to `events` fired from the [bloc].
/// [BlocEventConsumer] is analogous to a nested `BlocEventListener`
/// and `BlocBuilder` but reduces the amount of boilerplate needed.
/// [BlocEventConsumer] should only be used when it is necessary to both
/// rebuild UI on state changes in the [bloc], and execute other reactions
/// upon `events` fired from the [bloc].
///
/// [BlocEventConsumer] takes a required `BlocWidgetBuilder`
/// and `EventedBlocWidgetListener` and an optional [bloc],
/// `BlocBuilderCondition`, and `EventedBlocListenerCondition`.
///
/// If the [bloc] parameter is omitted, [BlocEventConsumer] will automatically
/// perform a lookup using `BlocProvider` and the current `BuildContext`.
///
/// ```dart
/// BlocEventConsumer<BlocA, BlocAEvent, BlocAState>(
///   listener: (context, bloc, event) {
///     // do stuff here based on BlocA's fired event
///   },
///   builder: (context, state) {
///     // return widget here based on BlocA's state
///   }
/// )
/// ```
///
/// An optional [listenWhen] and [buildWhen] can be implemented for more
/// granular control over when [listener] and [builder] are called.
///
/// {@macro bloc_event_listener_listen_when}
///
/// The [buildWhen] will be invoked on each [bloc] `state` change. It takes
/// the previous `state` and current `state` and must return
/// a [bool] which determines whether or not the [builder] function will
/// be invoked.
/// The previous `state` will be initialized to the `state` of the [bloc] when
/// the [BlocEventConsumer] is initialized.
///
/// [listenWhen] and [buildWhen] are optional and if they aren't implemented,
/// they will default to `true`.
///
/// ```dart
/// BlocEventConsumer<BlocA, BlocAEvent, BlocAState>(
///   listenWhen: (bloc, event) {
///     // return true/false to determine whether or not
///     // to invoke listener with event
///   },
///   listener: (context, bloc, event) {
///     // do stuff here based on BlocA's fired event
///   },
///   buildWhen: (previous, current) {
///     // return true/false to determine whether or not
///     // to rebuild the widget with state
///   },
///   builder: (context, state) {
///     // return widget here based on BlocA's state
///   }
/// )
/// ```
/// {@endtemplate}
class BlocEventConsumer<B extends EventedMixin<E, S>, E, S>
    extends StatefulWidget {
  /// {@macro bloc_event_consumer}
  const BlocEventConsumer({
    required this.listener,
    required this.builder,
    super.key,
    this.bloc,
    this.listenWhen,
    this.buildWhen,
  });

  /// The [bloc] whose `state` will be listened to.
  /// Whenever the [bloc]'s `state` changes, [listener] will be invoked.
  final B? bloc;

  /// The [BlocWidgetListener] which will be called on every `state` change.
  /// This [listener] should be used for any code which needs to execute
  /// in response to a `state` change.
  final EventedBlocWidgetListener<B, E> listener;

  /// See [BlocConsumer.builder]
  final BlocWidgetBuilder<S> builder;

  /// See [BlocConsumer.buildWhen]
  final BlocBuilderCondition<S>? buildWhen;

  /// {@macro bloc_event_listener_listen_when}
  final EventedBlocListenerCondition<B, E>? listenWhen;

  @override
  State<BlocEventConsumer<B, E, S>> createState() =>
      _BlocNotificationConsumerState<B, E, S>();
}

class _BlocNotificationConsumerState<B extends EventedMixin<E, S>, E, S>
    extends State<BlocEventConsumer<B, E, S>> {
  late B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
  }

  @override
  void didUpdateWidget(BlocEventConsumer<B, E, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<B>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) _bloc = currentBloc;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<B>();
    if (_bloc != bloc) _bloc = bloc;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bloc == null) {
      // Trigger a rebuild if the bloc reference has changed.
      // See https://github.com/felangel/bloc/issues/2127.
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }
    return BlocEventListener<B, E>(
      listener: widget.listener,
      listenWhen: widget.listenWhen,
      bloc: _bloc,
      child: BlocBuilder<B, S>(
        bloc: _bloc,
        builder: widget.builder,
        buildWhen: (previous, current) {
          return widget.buildWhen?.call(previous, current) ?? true;
        },
      ),
    );
  }
}
