import 'package:flutter/material.dart';
import 'package:flutter_evented_bloc/flutter_evented_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

enum CounterEvent { incremented, decremented }

class CounterCubit extends EventedCubit<CounterEvent, int> {
  CounterCubit({int seed = 0}) : super(seed);

  void increment() {
    emit(state + 1);
    fireEvent(CounterEvent.incremented);
  }

  void decrement() {
    emit(state - 1);
    fireEvent(CounterEvent.decremented);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.onListenerCalled});

  final EventedBlocWidgetListener<CounterCubit, CounterEvent>? onListenerCalled;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CounterCubit _counterCubit;

  @override
  void initState() {
    super.initState();
    _counterCubit = CounterCubit();
  }

  @override
  void dispose() {
    _counterCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BlocEventListener<CounterCubit, CounterEvent>(
          bloc: _counterCubit,
          listener: (context, bloc, event) {
            widget.onListenerCalled?.call(context, bloc, event);
          },
          child: Column(
            children: [
              ElevatedButton(
                key: const Key('cubit_listener_reset_button'),
                child: const SizedBox(),
                onPressed: () {
                  setState(() => _counterCubit = CounterCubit());
                },
              ),
              ElevatedButton(
                key: const Key('cubit_listener_noop_button'),
                child: const SizedBox(),
                onPressed: () {
                  setState(() => _counterCubit = _counterCubit);
                },
              ),
              ElevatedButton(
                key: const Key('cubit_listener_increment_button'),
                child: const SizedBox(),
                onPressed: () => _counterCubit.increment(),
              ),
              ElevatedButton(
                key: const Key('cubit_listener_decrement_button'),
                child: const SizedBox(),
                onPressed: () => _counterCubit.decrement(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('BlocListener', () {
    testWidgets(
        'throws AssertionError '
        'when child is not specified', (tester) async {
      const expected =
          '''BlocEventListener<CounterCubit, CounterEvent> used outside of MultiBlocEventListener must specify a child.''';
      await tester.pumpWidget(
        BlocEventListener<CounterCubit, CounterEvent>(
          bloc: CounterCubit(),
          listener: (context, bloc, event) {},
        ),
      );
      expect(
        tester.takeException(),
        isA<AssertionError>().having((e) => e.message, 'message', expected),
      );
    });

    testWidgets('renders child properly', (tester) async {
      const targetKey = Key('cubit_event_listener_container');
      await tester.pumpWidget(
        BlocEventListener<CounterCubit, CounterEvent>(
          bloc: CounterCubit(),
          listener: (_, __, ___) {},
          child: const SizedBox(key: targetKey),
        ),
      );
      expect(find.byKey(targetKey), findsOneWidget);
    });

    testWidgets('calls listener on single event triggered', (tester) async {
      final counterCubit = CounterCubit();
      final events = <CounterEvent>[];
      const expectedEvents = [CounterEvent.incremented];
      await tester.pumpWidget(
        BlocEventListener<CounterCubit, CounterEvent>(
          bloc: counterCubit,
          listener: (_, bloc, event) {
            events.add(event);
          },
          child: const SizedBox(),
        ),
      );
      counterCubit.increment();
      await tester.pump();
      expect(events, expectedEvents);
    });

    testWidgets('calls listener on multiple events triggered', (tester) async {
      final counterCubit = CounterCubit();
      final events = <CounterEvent>[];
      const expectedEvents = [
        CounterEvent.incremented,
        CounterEvent.incremented,
        CounterEvent.incremented,
      ];
      await tester.pumpWidget(
        BlocEventListener<CounterCubit, CounterEvent>(
          bloc: counterCubit,
          listener: (_, bloc, event) {
            events.add(event);
          },
          child: const SizedBox(),
        ),
      );
      counterCubit.increment();
      await tester.pump();
      counterCubit.increment();
      await tester.pump();
      counterCubit.increment();
      await tester.pump();
      expect(events, expectedEvents);
    });

    testWidgets(
        'updates when the cubit is changed at runtime to a different cubit '
        'and unsubscribes from old cubit', (tester) async {
      var listenerCallCount = 0;
      int? latestState;
      CounterEvent? latestEvent;
      final incrementFinder = find.byKey(
        const Key('cubit_listener_increment_button'),
      );
      final decrementFinder = find.byKey(
        const Key('cubit_listener_decrement_button'),
      );
      final resetCubitFinder = find.byKey(
        const Key('cubit_listener_reset_button'),
      );
      await tester.pumpWidget(
        MyApp(
          onListenerCalled: (_, bloc, event) {
            listenerCallCount++;
            latestState = bloc.state;
            latestEvent = event;
          },
        ),
      );

      await tester.tap(incrementFinder);
      await tester.pump();
      expect(listenerCallCount, 1);
      expect(latestState, 1);
      expect(latestEvent, CounterEvent.incremented);

      await tester.tap(incrementFinder);
      await tester.pump();
      expect(listenerCallCount, 2);
      expect(latestState, 2);
      expect(latestEvent, CounterEvent.incremented);

      await tester.tap(resetCubitFinder);
      await tester.pump();
      await tester.tap(decrementFinder);
      await tester.pump();
      expect(listenerCallCount, 3);
      expect(latestState, -1);
      expect(latestEvent, CounterEvent.decremented);
    });

    testWidgets(
        'does not update when the cubit is changed at runtime to same cubit '
        'and stays subscribed to current cubit', (tester) async {
      var listenerCallCount = 0;
      int? latestState;
      CounterEvent? latestEvent;
      final incrementFinder = find.byKey(
        const Key('cubit_listener_increment_button'),
      );
      final decrementFinder = find.byKey(
        const Key('cubit_listener_decrement_button'),
      );
      final noopCubitFinder = find.byKey(
        const Key('cubit_listener_noop_button'),
      );
      await tester.pumpWidget(
        MyApp(
          onListenerCalled: (_, bloc, event) {
            listenerCallCount++;
            latestState = bloc.state;
            latestEvent = event;
          },
        ),
      );

      await tester.tap(incrementFinder);
      await tester.pump();
      expect(listenerCallCount, 1);
      expect(latestState, 1);
      expect(latestEvent, CounterEvent.incremented);

      await tester.tap(incrementFinder);
      await tester.pump();
      expect(listenerCallCount, 2);
      expect(latestState, 2);
      expect(latestEvent, CounterEvent.incremented);

      await tester.tap(noopCubitFinder);
      await tester.pump();
      await tester.tap(decrementFinder);
      await tester.pump();
      expect(listenerCallCount, 3);
      expect(latestState, 1);
      expect(latestEvent, CounterEvent.decremented);
    });

    testWidgets('calls listenWhen and listener with correct event',
        (tester) async {
      var listenerCallCount = 0;
      final listenWhenEvent = <CounterEvent>[];
      final events = <CounterEvent>[];
      final counterCubit = CounterCubit();
      await tester.pumpWidget(
        BlocEventListener<CounterCubit, CounterEvent>(
          bloc: counterCubit,
          listenWhen: (bloc, event) {
            listenerCallCount++;
            if (listenerCallCount % 3 == 0) {
              listenWhenEvent.add(event);
              return true;
            }
            return false;
          },
          listener: (_, bloc, event) => events.add(event),
          child: const SizedBox(),
        ),
      );
      counterCubit
        ..increment()
        ..decrement()
        ..increment() // <- match
        ..decrement()
        ..increment()
        ..decrement() // <- match
        ..increment();
      await tester.pump();

      expect(events, [
        CounterEvent.incremented,
        CounterEvent.decremented,
      ]);
      expect(listenWhenEvent, [
        CounterEvent.incremented,
        CounterEvent.decremented,
      ]);
    });

    testWidgets(
        'infers the cubit from the context if the cubit is not provided',
        (tester) async {
      var listenWhenCallCount = 0;
      final states = <int>[];
      final events = <CounterEvent>[];
      final counterCubit = CounterCubit();
      const expectedStatesIfPumpedAfterAllCallsCompleted = [0, 0];
      const expectedStatesIfPumpedAfterEachCall = [1, 0];
      const expectedEvents = [
        CounterEvent.incremented,
        CounterEvent.decremented,
      ];
      await tester.pumpWidget(
        BlocProvider.value(
          value: counterCubit,
          child: BlocEventListener<CounterCubit, CounterEvent>(
            listenWhen: (bloc, event) {
              listenWhenCallCount++;
              return true;
            },
            listener: (context, bloc, event) {
              states.add(bloc.state); // state is actual bloc state value
              events.add(event);
            },
            child: const SizedBox(),
          ),
        ),
      );

      // Pump after all calls
      counterCubit
        ..increment()
        ..decrement();
      await tester.pump();

      expect(states, expectedStatesIfPumpedAfterAllCallsCompleted);
      expect(events, expectedEvents);
      expect(listenWhenCallCount, 2);

      // Pump after each call
      states.clear();
      events.clear();

      counterCubit.increment();
      await tester.pump();
      counterCubit.decrement();
      await tester.pump();

      expect(states, expectedStatesIfPumpedAfterEachCall);
      expect(events, expectedEvents);
      expect(listenWhenCallCount, 4);
    });

    testWidgets(
        'does not call listener when listenWhen returns false on single state '
        'change', (tester) async {
      final events = <CounterEvent>[];
      final counterCubit = CounterCubit();
      const expectedEvents = <CounterEvent>[];
      await tester.pumpWidget(
        BlocEventListener<CounterCubit, CounterEvent>(
          bloc: counterCubit,
          listenWhen: (_, __) => false,
          listener: (_, bloc, event) => events.add(event),
          child: const SizedBox(),
        ),
      );
      counterCubit.increment();
      await tester.pump();

      expect(events, expectedEvents);
    });

    testWidgets(
        'calls listener when listenWhen returns true on single state change',
        (tester) async {
      final events = <CounterEvent>[];
      final counterCubit = CounterCubit();
      const expectedEvents = <CounterEvent>[CounterEvent.incremented];
      await tester.pumpWidget(
        BlocEventListener<CounterCubit, CounterEvent>(
          bloc: counterCubit,
          listenWhen: (_, __) => true,
          listener: (_, bloc, event) => events.add(event),
          child: const SizedBox(),
        ),
      );
      counterCubit.increment();
      await tester.pump();

      expect(events, expectedEvents);
    });

    testWidgets(
        'does not call listener when listenWhen returns false '
        'on multiple state changes', (tester) async {
      final events = <CounterEvent>[];
      final counterCubit = CounterCubit();
      const expectedEvents = <CounterEvent>[];
      await tester.pumpWidget(
        BlocEventListener<CounterCubit, CounterEvent>(
          bloc: counterCubit,
          listenWhen: (_, __) => false,
          listener: (_, bloc, event) => events.add(event),
          child: const SizedBox(),
        ),
      );
      counterCubit.increment();
      await tester.pump();
      counterCubit.increment();
      await tester.pump();
      counterCubit.increment();
      await tester.pump();
      counterCubit.increment();
      await tester.pump();

      expect(events, expectedEvents);
    });

    testWidgets(
        'calls listener when listenWhen returns true on multiple state change',
        (tester) async {
      final states = <int>[];
      final events = <CounterEvent>[];
      final counterCubit = CounterCubit();
      const expectedStates = [1, 2, 3, 4];
      const expectedEvents = [
        CounterEvent.incremented,
        CounterEvent.incremented,
        CounterEvent.incremented,
        CounterEvent.incremented,
      ];
      await tester.pumpWidget(
        BlocEventListener<CounterCubit, CounterEvent>(
          bloc: counterCubit,
          listenWhen: (_, __) => true,
          listener: (_, bloc, event) {
            states.add(bloc.state);
            events.add(event);
          },
          child: const SizedBox(),
        ),
      );
      counterCubit.increment();
      await tester.pump();
      counterCubit.increment();
      await tester.pump();
      counterCubit.increment();
      await tester.pump();
      counterCubit.increment();
      await tester.pump();

      expect(states, expectedStates);
      expect(events, expectedEvents);
    });

    testWidgets(
        'updates subscription '
        'when provided bloc is changed', (tester) async {
      final firstCounterCubit = CounterCubit();
      final secondCounterCubit = CounterCubit(seed: 100);

      final states = <int>[];
      const expectedStates = [1, 101];

      await tester.pumpWidget(
        BlocProvider.value(
          value: firstCounterCubit,
          child: BlocEventListener<CounterCubit, CounterEvent>(
            listener: (_, bloc, event) => states.add(bloc.state),
            child: const SizedBox(),
          ),
        ),
      );
      firstCounterCubit.increment();

      await tester.pumpWidget(
        BlocProvider.value(
          value: secondCounterCubit,
          child: BlocEventListener<CounterCubit, CounterEvent>(
            listener: (_, bloc, event) => states.add(bloc.state),
            child: const SizedBox(),
          ),
        ),
      );
      secondCounterCubit.increment();
      await tester.pump();

      expect(states, expectedStates);

      firstCounterCubit.increment();
      await tester.pump();

      expect(states, expectedStates);
    });
  });
}
