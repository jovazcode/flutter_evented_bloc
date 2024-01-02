// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_evented_bloc/flutter_evented_bloc.dart';

void main() {
  Bloc.observer = const AppBlocObserver();
  runApp(const App());
}

/// {@template app_bloc_observer}
/// Custom [EventedBlocObserver] that observes all bloc and cubit state
/// changes and fired events.
/// {@endtemplate}
class AppBlocObserver extends EventedBlocObserver {
  /// {@macro app_bloc_observer}
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (bloc is Cubit) print(change);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    print(transition);
  }

  @override
  void onFireEvent(EventedMixin bloc, Object? event) {
    super.onFireEvent(bloc, event);
    print('"${bloc.runtimeType}" fired Event => $event');
  }
}

/// {@template app}
/// A [StatelessWidget] that:
/// * uses [bloc](https://pub.dev/packages/bloc) and
/// [flutter_bloc](https://pub.dev/packages/flutter_bloc)
/// to manage the state of a counter and the app theme.
/// {@endtemplate}
class App extends StatelessWidget {
  /// {@macro app}
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: const AppView(),
    );
  }
}

/// {@template app_view}
/// A [StatelessWidget] that:
/// * reacts to state changes in the [ThemeCubit]
/// and updates the theme of the [MaterialApp].
/// * renders the [CounterPage].
/// {@endtemplate}
class AppView extends StatelessWidget {
  /// {@macro app_view}
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeData>(
      builder: (_, theme) {
        return MaterialApp(
          theme: theme,
          home: const CounterPage(),
        );
      },
    );
  }
}

/// {@template counter_page}
/// A [StatelessWidget] that:
/// * provides a [CounterBloc] to the [CounterView].
/// {@endtemplate}
class CounterPage extends StatelessWidget {
  /// {@macro counter_page}
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterBloc(),
      child: const CounterView(),
    );
  }
}

/// {@template counter_view}
/// A [StatelessWidget] that:
/// * demonstrates how to consume and interact with a [CounterBloc].
/// {@endtemplate}
class CounterView extends StatelessWidget {
  /// {@macro counter_view}
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: BlocBuilder<CounterBloc, int>(
          builder: (context, count) {
            return Text(
              '$count',
              style: Theme.of(context).textTheme.displayLarge,
            );
          },
        ),
      ),
      // We are using `BlocEventListener` to listen to events fired by the bloc,
      // so that we can show a snack message when the user tries to
      // increment or decrement the counter value outside the allowed
      // range [0, 10].
      floatingActionButton: BlocEventListener<CounterBloc, CounterEvent>(
        listener: (context, bloc, event) {
          if (event is MinCountValueReached) {
            _showSnackMessage(context, 'Cannot go below ${event.value}');
          } else if (event is MaxCountValueReached) {
            _showSnackMessage(context, 'Cannot go above ${event.value}');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                context.read<CounterBloc>().add(CounterIncrementPressed());
              },
            ),
            const SizedBox(height: 4),
            FloatingActionButton(
              child: const Icon(Icons.remove),
              onPressed: () {
                context.read<CounterBloc>().add(CounterDecrementPressed());
              },
            ),
            const SizedBox(height: 4),
            FloatingActionButton(
              child: const Icon(Icons.brightness_6),
              onPressed: () {
                context.read<ThemeCubit>().toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }
}

bool _snackIsVisible = false;
String? _snackMessage;
void _showSnackMessage(BuildContext context, String message) {
  if (_snackIsVisible && _snackMessage == message) return;
  _snackIsVisible = true;
  _snackMessage = message;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(content: Text(message)),
      )
      .closed
      .then((reason) {
    if (reason == SnackBarClosedReason.hide) return;
    _snackIsVisible = false;
    _snackMessage = null;
  });
}

/// Event processed and/or fired by [CounterBloc].
abstract class CounterEvent {}

/// Notifies bloc to increment state.
class CounterIncrementPressed extends CounterEvent {}

/// Notifies bloc to decrement state.
class CounterDecrementPressed extends CounterEvent {}

/// {@template min_count_value_reached}
/// Notifies when bloc prevents counter from going below min value.
/// {@endtemplate}
class MinCountValueReached extends CounterEvent {
  /// {@macro min_count_value_reached}
  MinCountValueReached([this.value = 0]);

  final int value;

  @override
  String toString() {
    return 'MinCountValueReached { value: $value }';
  }
}

/// {@template max_count_value_reached}
/// Notifies when bloc prevents counter from exceeding max value.
/// {@endtemplate}
class MaxCountValueReached extends CounterEvent {
  /// {@macro max_count_value_reached}
  MaxCountValueReached([this.value = 10]);

  final int value;

  @override
  String toString() {
    return 'MaxCountValueReached { value: $value }';
  }
}

/// {@template counter_bloc}
/// An [EventedBloc] that manages an `int` as its state.
///
/// The bloc prevents the counter from going below 0,
/// and from exceeding 10.
/// {@endtemplate}
class CounterBloc extends EventedBloc<CounterEvent, int> {
  /// {@macro counter_bloc}
  CounterBloc() : super(0) {
    on<CounterIncrementPressed>((event, emit) {
      if (state == 10) {
        fireEvent(MaxCountValueReached());
        return;
      }
      emit(state + 1);
    });
    on<CounterDecrementPressed>((event, emit) {
      if (state == 0) {
        fireEvent(MinCountValueReached());
        return;
      }
      emit(state - 1);
    });
  }
}

/// {@template brightness_cubit}
/// A simple [Cubit] that manages the [ThemeData] as its state.
/// {@endtemplate}
class ThemeCubit extends Cubit<ThemeData> {
  /// {@macro brightness_cubit}
  ThemeCubit() : super(_lightTheme);

  static final _lightTheme = ThemeData(
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      foregroundColor: Colors.white,
    ),
    brightness: Brightness.light,
  );

  static final _darkTheme = ThemeData(
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      foregroundColor: Colors.black,
    ),
    brightness: Brightness.dark,
  );

  /// Toggles the current brightness between light and dark.
  void toggleTheme() {
    emit(state.brightness == Brightness.dark ? _lightTheme : _darkTheme);
  }
}
