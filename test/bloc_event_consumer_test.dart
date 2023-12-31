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

void main() {
  group('BlocEventConsumer', () {
    testWidgets(
        'accesses the bloc directly and passes initial state to builder and '
        'nothing to listener', (tester) async {
      final counterCubit = CounterCubit();
      final listenerEvents = <CounterEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocEventConsumer<CounterCubit, CounterEvent, int>(
              bloc: counterCubit,
              builder: (context, state) {
                return Text('State: $state');
              },
              listener: (_, bloc, event) {
                listenerEvents.add(event);
              },
            ),
          ),
        ),
      );
      expect(find.text('State: 0'), findsOneWidget);
      expect(listenerEvents, isEmpty);
    });

    testWidgets(
        'accesses the bloc directly '
        'and passes multiple states and events to builder and listener',
        (tester) async {
      final counterCubit = CounterCubit();
      final listenerEvents = <CounterEvent>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocEventConsumer<CounterCubit, CounterEvent, int>(
              bloc: counterCubit,
              builder: (context, state) {
                return Text('State: $state');
              },
              listener: (_, bloc, event) {
                listenerEvents.add(event);
              },
            ),
          ),
        ),
      );
      expect(find.text('State: 0'), findsOneWidget);
      expect(listenerEvents, isEmpty);
      counterCubit.increment();
      await tester.pump();
      expect(find.text('State: 1'), findsOneWidget);
      expect(listenerEvents, [CounterEvent.incremented]);
    });

    testWidgets(
        'accesses the bloc via context and passes initial state to builder',
        (tester) async {
      final counterCubit = CounterCubit();
      final listenerEvents = <CounterEvent>[];
      await tester.pumpWidget(
        BlocProvider<CounterCubit>.value(
          value: counterCubit,
          child: MaterialApp(
            home: Scaffold(
              body: BlocEventConsumer<CounterCubit, CounterEvent, int>(
                bloc: counterCubit,
                builder: (context, state) {
                  return Text('State: $state');
                },
                listener: (_, bloc, event) {
                  listenerEvents.add(event);
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('State: 0'), findsOneWidget);
      expect(listenerEvents, isEmpty);
    });

    testWidgets('does not trigger rebuilds when buildWhen evaluates to false',
        (tester) async {
      final counterCubit = CounterCubit();
      final listenerEvents = <CounterEvent>[];
      final builderStates = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocEventConsumer<CounterCubit, CounterEvent, int>(
              bloc: counterCubit,
              buildWhen: (previous, current) => (previous + current) % 3 == 0,
              builder: (context, state) {
                builderStates.add(state);
                return Text('State: $state');
              },
              listener: (_, bloc, event) {
                listenerEvents.add(event);
              },
            ),
          ),
        ),
      );
      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerEvents, isEmpty);

      counterCubit.increment();
      await tester.pump();

      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerEvents, [CounterEvent.incremented]);

      counterCubit.increment();
      await tester.pumpAndSettle();

      expect(find.text('State: 2'), findsOneWidget);
      expect(builderStates, [0, 2]);
      expect(listenerEvents, [
        CounterEvent.incremented,
        CounterEvent.incremented,
      ]);
    });

    testWidgets(
        'does not trigger rebuilds when '
        'buildWhen evaluates to false (inferred bloc)', (tester) async {
      final counterCubit = CounterCubit();
      final listenerEvents = <CounterEvent>[];
      final builderStates = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: counterCubit,
              child: BlocEventConsumer<CounterCubit, CounterEvent, int>(
                buildWhen: (previous, current) => (previous + current) % 3 == 0,
                builder: (context, state) {
                  builderStates.add(state);
                  return Text('State: $state');
                },
                listener: (_, bloc, event) {
                  listenerEvents.add(event);
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerEvents, isEmpty);

      counterCubit.increment();
      await tester.pump();

      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerEvents, [CounterEvent.incremented]);

      counterCubit.increment();
      await tester.pumpAndSettle();

      expect(find.text('State: 2'), findsOneWidget);
      expect(builderStates, [0, 2]);
      expect(listenerEvents, [
        CounterEvent.incremented,
        CounterEvent.incremented,
      ]);
    });

    testWidgets('updates when cubit/bloc reference has changed',
        (tester) async {
      const buttonKey = Key('__button__');
      var counterCubit = CounterCubit();
      final listenerEvents = <CounterEvent>[];
      final builderStates = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BlocEventConsumer<CounterCubit, CounterEvent, int>(
                  bloc: counterCubit,
                  builder: (context, state) {
                    builderStates.add(state);
                    return TextButton(
                      key: buttonKey,
                      onPressed: () => setState(() {}),
                      child: Text('State: $state'),
                    );
                  },
                  listener: (_, bloc, event) {
                    listenerEvents.add(event);
                  },
                );
              },
            ),
          ),
        ),
      );
      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerEvents, isEmpty);

      counterCubit.increment();
      await tester.pump();

      expect(find.text('State: 1'), findsOneWidget);
      expect(builderStates, [0, 1]);
      expect(listenerEvents, [
        CounterEvent.incremented,
      ]);

      counterCubit = CounterCubit();
      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();

      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0, 1, 0]);
      expect(listenerEvents, [
        CounterEvent.incremented,
      ]);
    });

    testWidgets('does not trigger listen when listenWhen evaluates to false',
        (tester) async {
      final counterCubit = CounterCubit();
      final listenerEvents = <CounterEvent>[];
      final builderStates = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocEventConsumer<CounterCubit, CounterEvent, int>(
              bloc: counterCubit,
              builder: (context, state) {
                builderStates.add(state);
                return Text('State: $state');
              },
              listenWhen: (bloc, event) => event == CounterEvent.decremented,
              listener: (_, bloc, event) {
                listenerEvents.add(event);
              },
            ),
          ),
        ),
      );
      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0]);
      expect(listenerEvents, isEmpty);

      counterCubit.increment();
      await tester.pump();

      expect(find.text('State: 1'), findsOneWidget);
      expect(builderStates, [0, 1]);
      expect(listenerEvents, isEmpty);

      counterCubit.decrement();
      await tester.pumpAndSettle();

      expect(find.text('State: 0'), findsOneWidget);
      expect(builderStates, [0, 1, 0]);
      expect(listenerEvents, [CounterEvent.decremented]);
    });
  });
}
