---
trigger: always_on
---

## Flutter Best Practices
* **Immutability:** Stateless widgets are immutable.
* **Composition:** Prefer composition over inheritance.
* **Private Widgets:** Break large build() trees into private widgets.
* **List Performance:** Use ListView.builder / SliverList.
* **Isolates:** Use compute() for heavy tasks.
* **Const constructors:** Use const where possible.
* **Performance:** Avoid doing work in build().

## API Design Principles
* **Consider the User**
* **Documentation is Essential**

## Application Architecture
* **Separation of Concerns**
* **Layers:** Presentation / Domain / Data / Core.
* **Feature-based Organization:** For large projects.

## Lint Rules
Use `flutter_lints` + custom rules.

## State Management
* Prefer built-in solutions: ValueNotifier, ChangeNotifier.
* Streams, StreamBuilder.
* Futures, FutureBuilder.
* ValueListenableBuilder example included.
* MVVM pattern for complex apps.
* Manual DI preferred.
* Provider allowed if explicitly requested.

## Data Flow
* Data structures as models.
* Repositories for abstraction.

## Routing
* Use go_router.
* Example with GoRoute, redirect, deep linking.
* Navigator for simple screens.
