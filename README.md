<p align="center">
  <img src="https://github.com/jovaz21/flutter_flutter_evented_bloc/blob/main/screenshots/logo.png" height="300" alt="Flutter Evented Bloc">
</p>

# Flutter Evented Bloc

[![build][build_badge]][build_link]
[![coverage][coverage_badge]][build_link]
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

[build_link]: https://github.com/jovaz21/flutter_evented_bloc/actions/workflows/main.yaml
[pub_link]: https://pub.dev/packages/flutter_evented_bloc
[build_badge]: https://github.com/jovaz21/flutter_evented_bloc/actions/workflows/main.yaml/badge.svg
[coverage_badge]: https://github.com/jovaz21/flutter_evented_bloc/blob/main/coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_badge]: https://img.shields.io/pub/v/flutter_evented_bloc.svg
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis

Widgets that make it easy to integrate evented blocs and cubits into [Flutter](https://flutter.dev). Built to work with [package:evented_bloc](https://pub.dev/packages/evented_bloc).

## Quick Start 🚀

### BlocEventListener

**BlocEventListener** is a Flutter widget which takes a `EventedBlocWidgetListener` and an optional `bloc` and invokes the `listener` in response to events triggered/fired from the bloc. It should be used for functionality that needs to occur once such as navigation, showing a `SnackBar`, showing a `Dialog`, etc...

If the bloc parameter is omitted, `BlocEventListener` will automatically perform a lookup using `BlocProvider` and the current `BuildContext`.

```dart
BlocEventListener<BlocA, BlocAEvent>(
  listener: (context, bloc, event) {
    // do stuff here based on the received event!!
  },
  child: Container(),
)
```

Only specify the bloc if you wish to provide a bloc that is otherwise not accessible via `BlocProvider` and the current `BuildContext`.

```dart
BlocEventListener<BlocA, BlocAEvent>(
  bloc: blocA,
  listener: (context, bloc, event) {
    // do stuff here based on the received event!!
  }
)
```

For fine-grained control over when the `listener` function is called an optional `listenWhen` can be provided. `listenWhen` takes the bloc and received event and returns a boolean. If `listenWhen` returns true, `listener` will be called with `event`. If `listenWhen` returns false, `listener` will not be called.

```dart
BlocEventListener<BlocA, BlocAEvent>(
  listenWhen: (bloc, event) {
    // return true/false to determine whether or not
    // to call listener with event
  },
  listener: (context, bloc, event) {
    // do stuff here based on the received event!!
  },
  child: Container(),
)
```

### MultiBlocEventListener

**MultiBlocEventListener** is a Flutter widget that merges multiple `BlocEventListener` widgets into one.
`MultiBlocEventListener` improves the readability and eliminates the need to nest multiple `BlocEventListeners`.
By using `MultiBlocEventListener` we can go from:

```dart
BlocEventListener<BlocA, BlocAEvent>(
  listener: (context, bloc, event) {},
  child: BlocEventListener<BlocB, BlocBEvent>(
    listener: (context, bloc, event) {},
    child: BlocEventListener<BlocC, BlocCEvent>(
      listener: (context, bloc, event) {},
      child: ChildA(),
    ),
  ),
)
```

to:

```dart
MultiBlocListener(
  listeners: [
    BlocEventListener<BlocA, BlocAEvent>(
      listener: (context, bloc, event) {},
    ),
    BlocEventListener<BlocB, BlocBEvent>(
      listener: (context, bloc, event) {},
    ),
    BlocEventListener<BlocC, BlocCEvent>(
      listener: (context, bloc, event) {},
    ),
  ],
  child: ChildA(),
)
```

### BlocEventConsumer

**BlocEventConsumer** exposes a `builder` and `listener` in order to react
to `events` fired from the `bloc`.
`BlocEventConsumer` is analogous to a nested `BlocEventListener`
and `BlocBuilder` but reduces the amount of boilerplate needed.
`BlocEventConsumer` should only be used when it is necessary to both
rebuild UI on state changes in the `bloc`, and execute other reactions
upon `events` fired from the `bloc`.

`BlocEventConsumer` takes a required `BlocWidgetBuilder` and `EventedBlocWidgetListener` and an optional `bloc`,
`BlocBuilderCondition`, and `EventedBlocListenerCondition`.

If the `bloc` parameter is omitted, `BlocEventConsumer` will automatically
perform a lookup using `BlocProvider` and the current `BuildContext`.

```dart
BlocEventConsumer<BlocA, BlocAEvent, BlocAState>(
  listener: (context, bloc, event) {
    // do stuff here based on BlocA's fired event
  },
  builder: (context, state) {
    // return widget here based on BlocA's state
  }
)
```

An optional `listenWhen` and `buildWhen` can be implemented for more granular control over when `listener` and `builder` are called.

`listenWhen` will be invoked on each `event` fired from given `bloc`.
`listenWhen` takes the fired `event` and must return a `bool` which
determines whether or not the `listener` function should be invoked.
`listenWhen` is optional and if omitted, it will default to `true`.

```dart
BlocEventListener<BlocA, BlocAEvent>(
  listenWhen: (bloc, event) {
    // return true/false to determine whether or not
    // to invoke listener with event
  },
  listener: (context, bloc event) {
    // do stuff here based on BlocA's fired event
  }
  child: Container(),
)
```

The `buildWhen` will be invoked on each `bloc` `state` change. It takes
the previous `state` and current `state` and must return
a `bool` which determines whether or not the `builder` function will
be invoked.

The previous `state` will be initialized to the `state` of the `bloc` when
the `BlocEventConsumer` is initialized.

`listenWhen` and `buildWhen` are optional and if they aren't implemented,
they will default to `true`.

```dart
BlocEventConsumer<BlocA, BlocAEvent, BlocAState>(
  listenWhen: (bloc, event) {
    // return true/false to determine whether or not
    // to invoke listener with event
  },
  listener: (context, bloc, event) {
    // do stuff here based on BlocA's fired event
  },
  buildWhen: (previous, current) {
    // return true/false to determine whether or not
    // to rebuild the widget with state
  },
  builder: (context, state) {
    // return widget here based on BlocA's state
  }
)
```
