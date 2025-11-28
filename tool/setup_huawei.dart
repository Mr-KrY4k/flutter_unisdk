#!/usr/bin/env dart
// Скрипт автоматической настройки Huawei HMS для Flutter проекта

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Ошибка: Не указан путь к Flutter проекту');
    print('');
    print('Использование:');
    print('  dart tool/setup_huawei.dart <путь_к_flutter_проекту>');
    print('');
    print('Пример:');
    print('  dart tool/setup_huawei.dart /path/to/your/flutter/project');
    exit(1);
  }

  final projectPath = args[0];
  final androidPath = '$projectPath/android';
  
  if (!Directory(androidPath).existsSync()) {
    print('❌ Ошибка: Папка android не найдена по пути: $androidPath');
    exit(1);
  }

  print('🔧 Настройка Huawei HMS для проекта: $projectPath');
  print('');

  try {
    setupSettingsGradle(androidPath);
    setupAppBuildGradle(androidPath);
    
    print('');
    print('✅ Настройка завершена успешно!');
    print('');
    print('📝 Следующий шаг:');
    print('   Добавьте файл agconnect-services.json в папку android/app/');
    print('');
  } catch (e, stackTrace) {
    print('❌ Ошибка при настройке: $e');
    print(stackTrace);
    exit(1);
  }
}

void setupSettingsGradle(String androidPath) {
  final settingsFile = File('$androidPath/settings.gradle.kts');
  if (!settingsFile.existsSync()) {
    print('⚠️  Предупреждение: settings.gradle.kts не найден, пропускаю...');
    return;
  }

  String content = settingsFile.readAsStringSync();
  bool changed = false;
  
  // Добавить Huawei репозиторий если его нет
  if (!content.contains('developer.huawei.com/repo')) {
    // Ищем блок repositories в pluginManagement
    if (content.contains('pluginManagement')) {
      final regex = RegExp(r'(repositories\s*\{[^\}]*)(gradlePluginPortal\(\))', dotAll: true);
      if (regex.hasMatch(content)) {
        content = content.replaceFirst(
          regex,
          r'$1$2\n        maven { url = uri("https://developer.huawei.com/repo/") }',
        );
        changed = true;
        print('✅ Добавлен Huawei репозиторий в settings.gradle.kts');
      } else {
        // Попробуем другой паттерн
        final regex2 = RegExp(r'(repositories\s*\{[^\}]*)(mavenCentral\(\))', dotAll: true);
        if (regex2.hasMatch(content)) {
          content = content.replaceFirst(
            regex2,
            r'$1$2\n        maven { url = uri("https://developer.huawei.com/repo/") }',
          );
          changed = true;
          print('✅ Добавлен Huawei репозиторий в settings.gradle.kts');
        }
      }
    }
  } else {
    print('ℹ️  Huawei репозиторий уже присутствует в settings.gradle.kts');
  }

  // Добавить resolutionStrategy если его нет
  if (!content.contains('resolutionStrategy')) {
    if (content.contains('pluginManagement')) {
      // Ищем закрывающую скобку pluginManagement
      final regex = RegExp(r'(repositories\s*\{[^\}]*\})', dotAll: true);
      if (regex.hasMatch(content)) {
        const resolutionStrategy = '''
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == "com.huawei.agconnect") {
                useModule("com.huawei.agconnect:agcp:1.9.1.303")
            }
        }
    }
''';
        content = content.replaceFirst(
          regex,
          '\$1$resolutionStrategy',
        );
        changed = true;
        print('✅ Добавлен resolutionStrategy в settings.gradle.kts');
      }
    }
  } else {
    print('ℹ️  resolutionStrategy уже присутствует в settings.gradle.kts');
  }

  // Добавить Huawei plugin в блок plugins если его нет
  if (!content.contains('id("com.huawei.agconnect")')) {
    // Ищем блок plugins
    final regex = RegExp(
      r'(plugins\s*\{[^\}]*)(id\("org\.jetbrains\.kotlin\.android"\)[^\}]*)(\})',
      dotAll: true,
    );
    if (regex.hasMatch(content)) {
      content = content.replaceFirst(
        regex,
        r'$1$2\n    id("com.huawei.agconnect") version "1.9.1.303" apply false\n$3',
      );
      changed = true;
      print('✅ Добавлен плагин com.huawei.agconnect в settings.gradle.kts');
    }
  } else {
    print('ℹ️  Плагин com.huawei.agconnect уже присутствует в settings.gradle.kts');
  }

  if (changed) {
    settingsFile.writeAsStringSync(content);
  }
}

void setupAppBuildGradle(String androidPath) {
  final buildFile = File('$androidPath/app/build.gradle.kts');
  if (!buildFile.existsSync()) {
    print('⚠️  Предупреждение: app/build.gradle.kts не найден, пропускаю...');
    return;
  }

  String content = buildFile.readAsStringSync();
  
  // Добавить Huawei plugin если его нет
  if (!content.contains('id("com.huawei.agconnect")')) {
    // Ищем блок plugins
    final regex = RegExp(
      r'(plugins\s*\{[^\}]*)(id\("dev\.flutter\.flutter-gradle-plugin"\)[^\}]*)(\})',
      dotAll: true,
    );
    if (regex.hasMatch(content)) {
      content = content.replaceFirst(
        regex,
        r'$1$2\n    id("com.huawei.agconnect")\n$3',
      );
      buildFile.writeAsStringSync(content);
      print('✅ Добавлен плагин com.huawei.agconnect в app/build.gradle.kts');
    } else {
      // Попробуем другой паттерн
      final regex2 = RegExp(
        r'(plugins\s*\{[^\}]*)(id\("kotlin-android"\)[^\}]*)(\})',
        dotAll: true,
      );
      if (regex2.hasMatch(content)) {
        content = content.replaceFirst(
          regex2,
          r'$1$2\n    id("com.huawei.agconnect")\n$3',
        );
        buildFile.writeAsStringSync(content);
        print('✅ Добавлен плагин com.huawei.agconnect в app/build.gradle.kts');
      } else {
        print('⚠️  Не удалось найти блок plugins в app/build.gradle.kts');
        print('   Добавьте вручную: id("com.huawei.agconnect")');
      }
    }
  } else {
    print('ℹ️  Плагин com.huawei.agconnect уже присутствует в app/build.gradle.kts');
  }
}

