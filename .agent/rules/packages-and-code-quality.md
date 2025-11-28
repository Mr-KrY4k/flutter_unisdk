---
trigger: always_on
---

## Package Management
* **Pub Tool:** To manage packages, use the `pub` tool, if available.
* **External Packages:** If a new feature requires an external package, use the
  `pub_dev_search` tool, if it is available. Otherwise, identify the most
  suitable and stable package from pub.dev.
* **Adding Dependencies:** To add a regular dependency, use the `pub` tool, if
  it is available. Otherwise, run `flutter pub add <package_name>`.
* **Adding Dev Dependencies:** To add a development dependency, use the `pub`
  tool, if it is available, with `dev:<package name>`. Otherwise, run `flutter
  pub add dev:<package_name>`.
* **Dependency Overrides:** To add a dependency override, use the `pub` tool, if
  it is available, with `override:<package name>:1.0.0`. Otherwise, run `flutter
  pub add override:<package_name>:1.0.0`.
* **Removing Dependencies:** To remove a dependency, use the `pub` tool, if it
  is available. Otherwise, run `dart pub remove <package_name>`.

## Code Quality
* **Code structure:** Adhere to maintainable code structure and separation of
  concerns (e.g., UI logic separate from business logic).
* **Naming conventions:** Avoid abbreviations and use meaningful, consistent,
  descriptive names for variables, functions, and classes.
* **Conciseness:** Write code that is as short as it can be while remaining
  clear.
* **Simplicity:** Write straightforward code. Code that is clever or
  obscure is difficult to maintain.
* **Error Handling:** Anticipate and handle potential errors. Don't let your
  code fail silently.
* **Styling:** Use 80-character line limits, PascalCase, camelCase, snake_case.
* **Functions:** Short and single-purpose.
* **Testing:** Write testable code.
* **Logging:** Use `logging` instead of `print`.

## Dart Best Practices
* **Effective Dart:** Follow official guidelines.
* **Library Organization:** Group related libraries.
* **API Documentation:** Add docs to all public APIs.
* **Async/Await:** Use Futures and Streams properly.
* **Null Safety:** Avoid unnecessary `!`.
* **Pattern Matching & Records:** Use when they simplify code.
* **Switch Expressions:** Prefer exhaustive ones.
