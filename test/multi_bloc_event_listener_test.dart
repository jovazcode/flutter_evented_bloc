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
  group('MultiBlocEventListener', () {
    testWidgets('calls listeners on events fired', (tester) async {
      final eventsA = <CounterEvent>[];
      const expectedEventsA = [
        CounterEvent.incremented,
        CounterEvent.incremented,
      ];
      final counterCubitA = CounterCubit();

      final eventsB = <CounterEvent>[];
      final expectedEventsB = [
        CounterEvent.incremented,
      ];
      final counterCubitB = CounterCubit();

      await tester.pumpWidget(
        MultiBlocEventListener(
          listeners: [
            BlocEventListener<CounterCubit, CounterEvent>(
              bloc: counterCubitA,
              listener: (context, bloc, event) => eventsA.add(event),
            ),
            BlocEventListener<CounterCubit, CounterEvent>(
              bloc: counterCubitB,
              listener: (context, bloc, event) => eventsB.add(event),
            ),
          ],
          child: const SizedBox(key: Key('multiCubitEventListener_child')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiCubitEventListener_child')),
        findsOneWidget,
      );

      counterCubitA.increment();
      await tester.pump();
      counterCubitA.increment();
      await tester.pump();
      counterCubitB.increment();
      await tester.pump();

      expect(eventsA, expectedEventsA);
      expect(eventsB, expectedEventsB);
    });

    testWidgets('calls listeners on events fired without explicit types',
        (tester) async {
      final eventsA = <CounterEvent>[];
      const expectedEventsA = [
        CounterEvent.incremented,
        CounterEvent.incremented,
      ];
      final counterCubitA = CounterCubit();

      final eventsB = <CounterEvent>[];
      final expectedEventsB = [
        CounterEvent.incremented,
      ];
      final counterCubitB = CounterCubit();

      await tester.pumpWidget(
        MultiBlocEventListener(
          listeners: [
            BlocEventListener(
              bloc: counterCubitA,
              listener: (context, CounterCubit bloc, CounterEvent event) =>
                  eventsA.add(event),
            ),
            BlocEventListener(
              bloc: counterCubitB,
              listener: (context, CounterCubit bloc, CounterEvent event) =>
                  eventsB.add(event),
            ),
          ],
          child: const SizedBox(key: Key('multiCubitEventListener_child')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('multiCubitEventListener_child')),
        findsOneWidget,
      );

      counterCubitA.increment();
      await tester.pump();
      counterCubitA.increment();
      await tester.pump();
      counterCubitB.increment();
      await tester.pump();

      expect(eventsA, expectedEventsA);
      expect(eventsB, expectedEventsB);
    });
  });
}
