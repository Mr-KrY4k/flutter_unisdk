#!/usr/bin/env dart
// Скрипт автоматической настройки Google Firebase для Flutter проекта

import 'dart:io';
import 'setup_common.dart';
import 'cleanup_android.dart';

/// Выполняет настройку Google для проекта
void setupGoogleForProject(String projectPath) {
  final androidPath = '$projectPath/android';

  if (!Directory(androidPath).existsSync()) {
    throw Exception('Папка android не найдена по пути: $androidPath');
  }

  // Сначала полностью очищаем проект от настроек провайдеров
  cleanAndroidProject(androidPath);
  cleanPubspec(projectPath);

  // Устанавливаем провайдер в gradle.properties плагина
  setProviderInPlugin('google');

  // Настраиваем Gradle в проекте
  setupGoogleGradle(androidPath);

  // Настраиваем AndroidManifest для Firebase
  setupGoogleManifest(androidPath);

  // Добавляем зависимости в pubspec.yaml
  setupGooglePubspec(projectPath);
}

void setupGoogleGradle(String androidPath) {
  // Проверяем наличие settings.gradle.kts или settings.gradle
  final settingsKts = File('$androidPath/settings.gradle.kts');
  final settingsGradle = File('$androidPath/settings.gradle');

  if (settingsKts.existsSync()) {
    setupGoogleSettingsKts(settingsKts);
  } else if (settingsGradle.existsSync()) {
    setupGoogleSettingsGradle(settingsGradle);
  } else {
    print(
      '⚠️  Предупреждение: settings.gradle.kts или settings.gradle не найден, пропускаю...',
    );
  }

  // Настроить app/build.gradle.kts или app/build.gradle
  setupGoogleAppBuildGradle(androidPath);
}

/// Настраивает AndroidManifest для Google Firebase (иконка уведомлений)
void setupGoogleManifest(String androidPath) {
  final manifestFile = File('$androidPath/app/src/main/AndroidManifest.xml');

  if (!manifestFile.existsSync()) {
    print(
      '⚠️  AndroidManifest.xml (app/src/main) не найден, пропускаю настройку meta-data Firebase',
    );
    return;
  }

  String content = manifestFile.readAsStringSync();

  const metaLine =
      '<meta-data android:name="com.google.firebase.messaging.default_notification_icon" android:resource="@drawable/firebase_icon_push"/>';

  if (content.contains(metaLine)) {
    print(
      'ℹ️  meta-data com.google.firebase.messaging.default_notification_icon уже присутствует в AndroidManifest.xml',
    );
    return;
  }

  // Ищем тег </application> и вставляем meta-data перед ним
  final appCloseIndex = content.indexOf('</application>');
  if (appCloseIndex == -1) {
    print(
      '⚠️  Не найден тег </application> в AndroidManifest.xml, пропускаю добавление meta-data',
    );
    return;
  }

  final insert = '        $metaLine\n';

  final newContent = StringBuffer()
    ..write(content.substring(0, appCloseIndex))
    ..write(insert)
    ..write(content.substring(appCloseIndex));

  manifestFile.writeAsStringSync(newContent.toString());
  print(
    '✅ Добавлен meta-data com.google.firebase.messaging.default_notification_icon в AndroidManifest.xml',
  );
}

void setupGoogleSettingsKts(File settingsFile) {
  String content = settingsFile.readAsStringSync();

  // Если плагины уже есть — ничего не делаем
  if (content.contains('id("com.google.gms.google-services")')) {
    print('ℹ️  Google плагины уже присутствуют в settings.gradle.kts');
    return;
  }

  // Ищем блок plugins
  final pluginsIndex = content.indexOf('plugins {');
  if (pluginsIndex == -1) {
    print('⚠️  Блок plugins не найден в settings.gradle.kts, пропускаю...');
    return;
  }

  // Ищем закрывающую скобку блока plugins – первую '}' после plugins-блока,
  // которая стоит в начале строки (возможно с пробелами перед ней)
  final closingBraceRegex = RegExp(r'^\s*}\s*$', multiLine: true);
  final match = closingBraceRegex.firstMatch(content.substring(pluginsIndex));
  if (match == null) {
    print('⚠️  Не удалось найти конец блока plugins в settings.gradle.kts');
    return;
  }

  final closingIndex = pluginsIndex + match.start;

  const googlePlugins = '''
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
''';

  // Вставляем плагины перед закрывающей скобкой блока plugins
  final newContent = StringBuffer()
    ..write(content.substring(0, closingIndex))
    ..writeln()
    ..write(googlePlugins)
    ..write(content.substring(closingIndex));

  settingsFile.writeAsStringSync(newContent.toString());
  print('✅ Добавлены Google плагины в settings.gradle.kts');
}

void setupGoogleSettingsGradle(File settingsFile) {
  String content = settingsFile.readAsStringSync();
  bool changed = false;

  // Добавить Google плагины в блок plugins если их нет (Groovy синтаксис)
  if (!content.contains("id 'com.google.gms.google-services'")) {
    // Ищем блок plugins и последний id перед закрывающей скобкой
    final regex = RegExp(
      '(plugins\\s*\\{[^\\}]*?id\\s+[^\\}]+?)(\\s*\\})',
      dotAll: true,
    );
    if (regex.hasMatch(content)) {
      content = content.replaceFirst(
        regex,
        r'$1' +
            '\n    id \'com.google.gms.google-services\' version \'4.4.2\' apply false\n    id \'com.google.firebase.crashlytics\' version \'3.0.2\' apply false' +
            r'$2',
      );
      changed = true;
      print('✅ Добавлены Google плагины в settings.gradle');
    }
  } else {
    print('ℹ️  Google плагины уже присутствуют в settings.gradle');
  }

  if (changed) {
    settingsFile.writeAsStringSync(content);
  }
}

void setupGoogleAppBuildGradle(String androidPath) {
  final appKts = File('$androidPath/app/build.gradle.kts');
  final appGradle = File('$androidPath/app/build.gradle');

  if (appKts.existsSync()) {
    _setupGoogleAppBuildGradleKts(appKts);
  } else if (appGradle.existsSync()) {
    _setupGoogleAppBuildGradleGradle(appGradle);
  } else {
    print(
      '⚠️  Предупреждение: app/build.gradle.kts или app/build.gradle не найден, пропускаю...',
    );
  }
}

void _setupGoogleAppBuildGradleKts(File buildFile) {
  String content = buildFile.readAsStringSync();
  bool changed = false;

  // --- PLUGINS ---
  if (!content.contains("id(\"com.google.gms.google-services\")")) {
    final pluginsIndex = content.indexOf('plugins {');
    if (pluginsIndex != -1) {
      final closingBraceRegex = RegExp(r'^\s*}\s*$', multiLine: true);
      final match = closingBraceRegex.firstMatch(
        content.substring(pluginsIndex),
      );
      if (match != null) {
        final closingIndex = pluginsIndex + match.start;

        const googlePlugins = '''
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
''';

        final newContent = StringBuffer()
          ..write(content.substring(0, closingIndex))
          ..writeln()
          ..write(googlePlugins)
          ..write(content.substring(closingIndex));

        content = newContent.toString();
        changed = true;
        print('✅ Добавлены Google плагины в app/build.gradle.kts');
      } else {
        print(
          '⚠️  Не удалось найти конец блока plugins в app/build.gradle.kts',
        );
      }
    } else {
      // Плагинов нет совсем — создаём блок plugins в начале файла
      const googlePluginsBlock = '''
plugins {
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

''';

      content = googlePluginsBlock + content;
      changed = true;
      print('✅ Создан блок plugins с Google плагинами в app/build.gradle.kts');
    }
  } else {
    print('ℹ️  Google плагины уже присутствуют в app/build.gradle.kts');
  }

  // --- DEPENDENCIES ---
  const depsToAdd = [
    'implementation("com.google.android.gms:play-services-location:21.3.0")',
    'implementation("com.android.installreferrer:installreferrer:2.2")',
  ];
  // Если хотя бы одной нет — добавляем
  final missingDeps = depsToAdd
      .where((d) => !content.contains(d.trim()))
      .toList();

  if (missingDeps.isNotEmpty) {
    int depsIndex = content.indexOf('dependencies {');

    if (depsIndex != -1) {
      // Есть блок dependencies – добавляем внутрь, конец ищем по балансу скобок
      int braceLevel = 0;
      int closingIndex = -1;
      for (var i = depsIndex; i < content.length; i++) {
        final ch = content[i];
        if (ch == '{') {
          braceLevel++;
        } else if (ch == '}') {
          braceLevel--;
          if (braceLevel == 0) {
            closingIndex = i;
            break;
          }
        }
      }

      if (closingIndex == -1) {
        print(
          '⚠️  Не удалось найти конец блока dependencies в app/build.gradle.kts',
        );
      } else {
        final insertIndex = closingIndex;

        final depsBlock = StringBuffer();
        for (final dep in missingDeps) {
          depsBlock.writeln('    $dep');
        }

        final newContent = StringBuffer()
          ..write(content.substring(0, insertIndex))
          ..writeln()
          ..write(depsBlock.toString())
          ..write(content.substring(insertIndex));

        content = newContent.toString();
        changed = true;
        print(
          '✅ Добавлены зависимости Google в существующий dependencies в app/build.gradle.kts',
        );
      }
    } else {
      // Нет блока dependencies – создаём его в конце файла
      final depsBlock = StringBuffer()
        ..writeln()
        ..writeln('dependencies {');
      for (final dep in missingDeps) {
        depsBlock.writeln('    $dep');
      }
      depsBlock.writeln('}');

      content = content + depsBlock.toString();
      changed = true;
      print(
        '✅ Создан блок dependencies и добавлены зависимости Google в app/build.gradle.kts',
      );
    }
  } else {
    print('ℹ️  Все зависимости Google уже присутствуют в app/build.gradle.kts');
  }

  if (changed) {
    buildFile.writeAsStringSync(content);
  }

  // --- BUILDTYPES ---
  _setupGoogleBuildTypesKts(buildFile);
}

void _setupGoogleAppBuildGradleGradle(File buildFile) {
  String content = buildFile.readAsStringSync();
  bool changed = false;

  // --- PLUGINS (apply plugin) для Groovy, если нужно — можно расширить позже ---
  if (!content.contains("id 'com.google.gms.google-services'") &&
      !content.contains('id("com.google.gms.google-services")')) {
    final pluginsIndex = content.indexOf('plugins {');
    if (pluginsIndex != -1) {
      final closingBraceRegex = RegExp(r'^\s*}\s*$', multiLine: true);
      final match = closingBraceRegex.firstMatch(
        content.substring(pluginsIndex),
      );
      if (match != null) {
        final closingIndex = pluginsIndex + match.start;

        const googlePlugins = '''
    id 'com.google.gms.google-services'
    id 'com.google.firebase.crashlytics'
''';

        final newContent = StringBuffer()
          ..write(content.substring(0, closingIndex))
          ..writeln()
          ..write(googlePlugins)
          ..write(content.substring(closingIndex));

        content = newContent.toString();
        changed = true;
        print('✅ Добавлены Google плагины в app/build.gradle');
      }
    }
  }

  // --- DEPENDENCIES ---
  const depsToAdd = [
    'implementation "com.google.android.gms:play-services-location:21.3.0"',
    'implementation "com.android.installreferrer:installreferrer:2.2"',
  ];

  final missingDeps = depsToAdd
      .where((d) => !content.contains(d.trim()))
      .toList();

  if (missingDeps.isNotEmpty) {
    int depsIndex = content.indexOf('dependencies {');

    if (depsIndex != -1) {
      // Есть блок dependencies – добавляем внутрь
      final closingBraceRegex = RegExp(r'^\s*}\s*$', multiLine: true);
      final match = closingBraceRegex.firstMatch(content.substring(depsIndex));
      if (match != null) {
        final closingIndex = depsIndex + match.start;

        final depsBlock = StringBuffer();
        for (final dep in missingDeps) {
          depsBlock.writeln('    $dep');
        }

        final newContent = StringBuffer()
          ..write(content.substring(0, closingIndex))
          ..writeln()
          ..write(depsBlock.toString())
          ..write(content.substring(closingIndex));

        content = newContent.toString();
        changed = true;
        print(
          '✅ Добавлены зависимости Google в существующий dependencies в app/build.gradle',
        );
      }
    } else {
      // Нет блока dependencies – создаём его в конце файла
      final depsBlock = StringBuffer()
        ..writeln()
        ..writeln('dependencies {');
      for (final dep in missingDeps) {
        depsBlock.writeln('    $dep');
      }
      depsBlock.writeln('}');

      content = content + depsBlock.toString();
      changed = true;
      print(
        '✅ Создан блок dependencies и добавлены зависимости Google в app/build.gradle',
      );
    }
  }

  if (changed) {
    buildFile.writeAsStringSync(content);
  }
}

/// Обеспечивает в app/build.gradle.kts блок buildTypes в виде:
/// buildTypes {
///   getByName("release") {
///     signingConfig = signingConfigs.getByName("release")
///   }
///   getByName("debug") {
///     isDebuggable = true
///   }
/// }
void _setupGoogleBuildTypesKts(File buildFile) {
  const fullBuildTypesBlock = '''
buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
    }

    getByName("debug") {
        isDebuggable = true
    }
}
''';

  var content = buildFile.readAsStringSync();

  // Если buildTypes уже есть – ПОЛНОСТЬЮ заменяем его на нужный вид
  final buildTypesStart = content.indexOf('buildTypes {');
  if (buildTypesStart != -1) {
    // Находим конец блока по балансу фигурных скобок
    int braceLevel = 0;
    int endIndex = -1;
    for (var i = buildTypesStart; i < content.length; i++) {
      final ch = content[i];
      if (ch == '{') {
        braceLevel++;
      } else if (ch == '}') {
        braceLevel--;
        if (braceLevel == 0) {
          endIndex = i;
          break;
        }
      }
    }

    if (endIndex == -1) {
      print(
        '⚠️  Не удалось найти конец блока buildTypes в app/build.gradle.kts',
      );
      return;
    }

    final before = content.substring(0, buildTypesStart);
    final after = content.substring(endIndex + 1);

    content = before + fullBuildTypesBlock + after;
    buildFile.writeAsStringSync(content);
    print('✅ Блок buildTypes приведён к нужному виду для Google');
    return;
  }

  // Если buildTypes нет – вставляем полный блок перед последней закрывающей скобкой файла
  final closingBraceRegex = RegExp(r'^\s*}\s*$', multiLine: true);
  final matches = closingBraceRegex.allMatches(content).toList();
  if (matches.isEmpty) {
    print(
      '⚠️  Не удалось определить место вставки buildTypes в app/build.gradle.kts',
    );
    return;
  }

  final lastClosing = matches.last;
  final insertIndex = lastClosing.start;

  final buffer = StringBuffer()
    ..write(content.substring(0, insertIndex))
    ..write(fullBuildTypesBlock)
    ..write(content.substring(insertIndex));

  buildFile.writeAsStringSync(buffer.toString());
  print('✅ Добавлен блок buildTypes для Google в app/build.gradle.kts');
}

void setupGooglePubspec(String projectPath) {
  final pubspecFile = File('$projectPath/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print(
      '⚠️  Предупреждение: pubspec.yaml не найден по пути: ${pubspecFile.path}, пропускаю...',
    );
    return;
  }

  final lines = pubspecFile.readAsLinesSync();

  // Google Firebase зависимости (с фиксированными минимальными версиями)
  final depsToEnsure = <String, String>{
    'firebase_core': '  firebase_core: ^4.0.0',
    'firebase_remote_config': '  firebase_remote_config: ^6.0.0',
    'firebase_messaging': '  firebase_messaging: ^16.0.0',
    'firebase_analytics': '  firebase_analytics: ^12.0.0',
    'firebase_crashlytics': '  firebase_crashlytics: ^5.0.0',
  };

  bool changed = false;

  // Находим индекс блока dependencies
  int depsIndex = lines.indexWhere(
    (l) => l.trimLeft().startsWith('dependencies:'),
  );

  if (depsIndex == -1) {
    // Если dependencies нет, создаём его после environment:
    final envIndex = lines.indexWhere(
      (l) => l.trimLeft().startsWith('environment:'),
    );
    if (envIndex != -1) {
      final insertAt = envIndex + 1;
      lines.insert(insertAt, '');
      lines.insert(insertAt + 1, 'dependencies:');
      depsIndex = insertAt + 1;
      changed = true;
      print('✅ Создан блок dependencies в pubspec.yaml');
    } else {
      print(
        '⚠️  Не удалось найти секцию environment в pubspec.yaml, пропускаю добавление зависимостей',
      );
      return;
    }
  }

  // Определяем место вставки внутри блока dependencies:
  // идём вниз от строки `dependencies:` пока строки начинаются с двух пробелов
  int insertIndex = depsIndex + 1;
  while (insertIndex < lines.length) {
    final line = lines[insertIndex];
    if (line.startsWith('  ') && line.trim().isNotEmpty) {
      insertIndex++;
      continue;
    }
    break;
  }

  // Для каждого dep добавляем или обновляем строку с версией
  for (final entry in depsToEnsure.entries) {
    final dep = entry.key;
    final depLine = entry.value;

    // Ищем существующую строку для этой зависимости
    final existingIndex = lines.indexWhere(
      (l) => l.trimLeft().startsWith('$dep:'),
    );

    if (existingIndex != -1) {
      final current = lines[existingIndex].trimRight();
      if (current != depLine) {
        // Обновляем до нужной версии
        lines[existingIndex] = depLine;
        changed = true;
        print('✅ Обновлена зависимость $dep до: $depLine');
      } else {
        print('ℹ️  Зависимость $dep уже имеет нужную версию в pubspec.yaml');
      }
      continue;
    }

    // Строки ещё нет — добавляем новую
    lines.insert(insertIndex, depLine);
    insertIndex++;
    changed = true;
    print('✅ Добавлена зависимость $dep в pubspec.yaml');
  }

  if (changed) {
    pubspecFile.writeAsStringSync(lines.join('\n'));
    print('✅ pubspec.yaml обновлён для Google Firebase');
  } else {
    print(
      'ℹ️  pubspec.yaml уже содержит все зависимости Google Firebase, изменений не требуется',
    );
  }
}
