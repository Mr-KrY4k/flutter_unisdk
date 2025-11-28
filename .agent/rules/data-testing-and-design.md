---
trigger: always_on
---

## Data Handling & Serialization
* Use json_serializable and json_annotation.
* Use snake_case via fieldRename.

## Logging
* Use dart:developer log().
* Example provided.

## Code Generation
* Use build_runner.
* Run: dart run build_runner build --delete-conflicting-outputs

## Testing
* Run via flutter test.
* Unit, widget, integration tests.
* Prefer fakes over mocks.

## Theming & Design
* Responsive UI.
* Typography hierarchy.
* Background textures.
* Shadows and depth.
* Icons.
* Light/Dark themes.
* ColorScheme.fromSeed.

## Assets & Images
* Declare in pubspec.yaml.
* Use Image.asset, Image.network.
* Provide loadingBuilder & errorBuilder.

## Material Theming
* Use ThemeData, Material 3.
* ThemeExtension for custom tokens.
* WidgetStateProperty examples.
