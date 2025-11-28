#!/usr/bin/env dart
// Скрипт автоматической настройки Huawei HMS для Flutter проекта

import 'dart:io';
import 'setup_common.dart';
import 'cleanup_android.dart';

const String _huaweiProguardRules = '''
-ignorewarnings
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes EnclosingMethod

## Huawei HMS
-keep class com.hianalytics.android.** { *; }
-keep class com.huawei.updatesdk.** { *; }
-keep class com.huawei.hms.** { *; }
-keep class com.huawei.hms.flutter.** { *; }

## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

-repackageclasses
''';

/// Выполняет настройку Huawei для проекта
void setupHuaweiForProject(String projectPath) {
  final androidPath = '$projectPath/android';

  if (!Directory(androidPath).existsSync()) {
    throw Exception('Папка android не найдена по пути: $androidPath');
  }

  // Сначала полностью очищаем проект от настроек провайдеров
  cleanAndroidProject(androidPath);
  cleanPubspec(projectPath);

  // Устанавливаем провайдер в gradle.properties плагина
  setProviderInPlugin('huawei');

  // Настраиваем Gradle в проекте
  setupHuaweiGradle(androidPath);

  // Добавляем ProGuard правила Huawei в приложение
  setupHuaweiProguard(androidPath);

  // Добавляем зависимости в pubspec.yaml
  setupHuaweiPubspec(projectPath);
}

void setupHuaweiGradle(String androidPath) {
  final settingsFile = File('$androidPath/settings.gradle.kts');
  if (!settingsFile.existsSync()) {
    print('⚠️  Предупреждение: settings.gradle.kts не найден, пропускаю...');
    return;
  }

  String content = settingsFile.readAsStringSync();
  bool changed = false;

  // --- repositories в pluginManagement ---
  final pmIndex = content.indexOf('pluginManagement');
  if (pmIndex != -1) {
    var reposIndex = content.indexOf('repositories {', pmIndex);

    // Если repositories нет – создаём его сразу после includeBuild или в начале pluginManagement
    if (reposIndex == -1) {
      final insertAfter = content.indexOf('includeBuild', pmIndex);
      final insertPos =
          insertAfter != -1 ? content.indexOf('\n', insertAfter) + 1 : pmIndex;

      const reposBlock = '''
    repositories {
        maven { url = uri("https://developer.huawei.com/repo/") }
    }
''';

      content = content.substring(0, insertPos) +
          reposBlock +
          content.substring(insertPos);
      changed = true;
      print('✅ Создан блок repositories с Huawei репозиторием в settings.gradle.kts');
    } else if (!content.contains('developer.huawei.com/repo')) {
      // repositories есть – добавляем внутрь только нашу строку maven { ... }
      int braceLevel = 0;
      int endIndex = -1;
      for (var i = reposIndex; i < content.length; i++) {
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

      if (endIndex != -1) {
        final before = content.substring(0, endIndex);
        final after = content.substring(endIndex);
        const huaweiRepoLine =
            '\n        maven { url = uri("https://developer.huawei.com/repo/") }';
        content = '$before$huaweiRepoLine$after';
        changed = true;
        print('✅ Добавлен Huawei репозиторий в settings.gradle.kts');
      }
    } else {
      print('ℹ️  Huawei репозиторий уже присутствует');
    }

    // --- resolutionStrategy / eachPlugin / if (...) ---
    // Ищем или создаём resolutionStrategy внутри pluginManagement
    var rsIndex = content.indexOf('resolutionStrategy', pmIndex);
    if (rsIndex == -1) {
      // Вставляем сразу после блока repositories
      reposIndex = content.indexOf('repositories {', pmIndex);
      if (reposIndex != -1) {
        int braceLevel = 0;
        int endIndex = -1;
        for (var i = reposIndex; i < content.length; i++) {
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

        if (endIndex != -1) {
          final insertPos = endIndex + 1;
          const rsBlock = '''

    resolutionStrategy {
        eachPlugin {
        }
    }
''';
          content = content.substring(0, insertPos) +
              rsBlock +
              content.substring(insertPos);
          changed = true;
          print('✅ Создан блок resolutionStrategy в settings.gradle.kts');
          rsIndex = content.indexOf('resolutionStrategy', pmIndex);
        }
      }
    }

    if (rsIndex != -1) {
      // Внутри resolutionStrategy ищем или создаём eachPlugin
      int braceLevel = 0;
      int rsStartBrace = content.indexOf('{', rsIndex);
      int rsEnd = -1;
      for (var i = rsStartBrace; i < content.length; i++) {
        final ch = content[i];
        if (ch == '{') {
          braceLevel++;
        } else if (ch == '}') {
          braceLevel--;
          if (braceLevel == 0) {
            rsEnd = i;
            break;
          }
        }
      }

      if (rsEnd != -1) {
        final rsBody = content.substring(rsStartBrace, rsEnd + 1);
        var body = rsBody;

        final eachIndexInBody = body.indexOf('eachPlugin');
        if (eachIndexInBody == -1) {
          // Создаём eachPlugin { } с нужным if
          const eachBlock = '''
    eachPlugin {
        if (requested.id.id == "com.huawei.agconnect") {
            useModule("com.huawei.agconnect:agcp:1.9.1.303")
        }
    }
''';
          body = body.replaceFirst('{', '{\n$eachBlock');
          changed = true;
          print('✅ Создан блок eachPlugin с Huawei правилом в settings.gradle.kts');
        } else if (!body.contains(
            'useModule("com.huawei.agconnect:agcp:1.9.1.303")')) {
          // eachPlugin есть, но нет нашего if – добавляем только его
          final eachIndex = body.indexOf('eachPlugin');
          final eachBraceStart = body.indexOf('{', eachIndex);
          braceLevel = 0;
          int eachEnd = -1;
          for (var i = eachBraceStart; i < body.length; i++) {
            final ch = body[i];
            if (ch == '{') {
              braceLevel++;
            } else if (ch == '}') {
              braceLevel--;
              if (braceLevel == 0) {
                eachEnd = i;
                break;
              }
            }
          }

          if (eachEnd != -1) {
            const ifBlock = '''
        if (requested.id.id == "com.huawei.agconnect") {
            useModule("com.huawei.agconnect:agcp:1.9.1.303")
        }
''';
            body = body.substring(0, eachEnd) +
                '\n$ifBlock' +
                body.substring(eachEnd);
            changed = true;
            print(
              '✅ Добавлено Huawei правило в existing eachPlugin в settings.gradle.kts',
            );
          }
        }

        if (body != rsBody) {
          content = content.substring(0, rsStartBrace) +
              body +
              content.substring(rsEnd + 1);
        }
      }
    }
  }

  // Добавить Huawei plugin в блок plugins если его нет
  if (!content.contains('id("com.huawei.agconnect")')) {
    // Ищем блок plugins
    final pluginsIndex = content.indexOf('plugins {');
    if (pluginsIndex != -1) {
      // Ищем закрывающую скобку блока plugins – первую '}' после plugins-блока,
      // которая стоит в начале строки (возможно с пробелами перед ней)
      final closingBraceRegex = RegExp(r'^\s*}\s*$', multiLine: true);
      final match = closingBraceRegex.firstMatch(
        content.substring(pluginsIndex),
      );
      if (match != null) {
        final closingIndex = pluginsIndex + match.start;

        const huaweiPluginLine =
            '    id("com.huawei.agconnect") version "1.9.1.303" apply false\n';

        final newContent = StringBuffer()
          ..write(content.substring(0, closingIndex))
          ..write(huaweiPluginLine)
          ..write(content.substring(closingIndex));

        content = newContent.toString();
        changed = true;
        print('✅ Добавлен плагин com.huawei.agconnect в settings.gradle.kts');
      }
    }
  }

  if (changed) {
    settingsFile.writeAsStringSync(content);
  }

  // Настроить корневой build.gradle.kts (buildscript + репозиторий Huawei)
  _setupHuaweiRootBuildGradle(androidPath);

  // Настроить app/build.gradle.kts
  setupHuaweiAppBuildGradle(androidPath);

  // Настроить AndroidManifest.xml приложения
  setupHuaweiAndroidManifest(androidPath);
}

/// Добавляет Huawei ProGuard правила в app/proguard-rules.pro
void setupHuaweiProguard(String androidPath) {
  final proguardFile = File('$androidPath/app/proguard-rules.pro');

  String existing = '';
  if (proguardFile.existsSync()) {
    existing = proguardFile.readAsStringSync();
  }

  // Если правила Huawei уже есть — ничего не делаем
  if (existing.contains('com.huawei.hms.flutter.**')) {
    print(
      'ℹ️  Huawei ProGuard правила уже присутствуют в app/proguard-rules.pro',
    );
    return;
  }

  final buffer = StringBuffer();

  if (existing.trim().isNotEmpty) {
    buffer
      ..write(existing.trimRight())
      ..write('\n\n');
  }

  buffer
    ..write(_huaweiProguardRules.trim())
    ..write('\n');

  proguardFile.writeAsStringSync(buffer.toString());

  print('✅ Добавлены Huawei ProGuard правила в app/proguard-rules.pro');
}

/// Добавляет Huawei репозиторий в allprojects.repositories и блок buildscript
/// в android/build.gradle.kts
void _setupHuaweiRootBuildGradle(String androidPath) {
  final rootBuildKts = File('$androidPath/build.gradle.kts');
  if (!rootBuildKts.existsSync()) {
    print(
      '⚠️  Предупреждение: build.gradle.kts не найден, пропускаю настройку allprojects',
    );
    return;
  }

  String content = rootBuildKts.readAsStringSync();

  // --- buildscript ---
  if (!content.contains('classpath("com.huawei.agconnect:agcp:1.9.1.303")')) {
    const buildscriptBlock = '''
buildscript {
    repositories {
        google()
        mavenCentral()
        maven(url = "https://developer.huawei.com/repo/")
        gradlePluginPortal()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.8.1")
        classpath("com.huawei.agconnect:agcp:1.9.1.303")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
    }
}

''';

    content = buildscriptBlock + content;
    print('✅ Добавлен Huawei buildscript в build.gradle.kts');
  } else {
    print('ℹ️  Huawei buildscript уже присутствует в build.gradle.kts');
  }

  // --- allprojects.repositories: Huawei repo ---
  if (!content.contains('developer.huawei.com/repo')) {
    final allProjectsIndex = content.indexOf('allprojects {');
    if (allProjectsIndex != -1) {
      final substring = content.substring(allProjectsIndex);
      final reposIndexInSub = substring.indexOf('repositories {');
      if (reposIndexInSub != -1) {
        final reposStart = allProjectsIndex + reposIndexInSub;
        final closingBraceRegex = RegExp(r'^\s*}\s*$', multiLine: true);
        final match = closingBraceRegex.firstMatch(
          content.substring(reposStart),
        );
        if (match != null) {
          final closingIndex = reposStart + match.start;
          const huaweiRepoLine =
              '        maven(url = "https://developer.huawei.com/repo/")\n';

          final newContent = StringBuffer()
            ..write(content.substring(0, closingIndex))
            ..write(huaweiRepoLine)
            ..write(content.substring(closingIndex));

          content = newContent.toString();
          print(
            '✅ Добавлен Huawei репозиторий в allprojects.repositories (build.gradle.kts)',
          );
        }
      }
    }
  } else {
    print('ℹ️  Huawei репозиторий уже присутствует в allprojects.repositories');
  }

  rootBuildKts.writeAsStringSync(content);
}

void setupHuaweiAppBuildGradle(String androidPath) {
  final buildFile = File('$androidPath/app/build.gradle.kts');
  if (!buildFile.existsSync()) {
    print('⚠️  Предупреждение: app/build.gradle.kts не найден, пропускаю...');
    return;
  }

  String content = buildFile.readAsStringSync();

  // Чиним возможный старый мусор вида "$1$2\n    id(\"com.huawei.agconnect\")\n$3"
  if (content.contains(r'$1$2\n    id("com.huawei.agconnect")\n$3')) {
    content = content.replaceAll(
      r'$1$2\n    id("com.huawei.agconnect")\n$3',
      '',
    );
  }

  bool changed = false;

  // --- ПЛАГИН Huawei в блоке plugins ---
  if (!content.contains('id("com.huawei.agconnect")')) {
    final pluginsIndex = content.indexOf('plugins {');
    if (pluginsIndex != -1) {
      // Есть блок plugins – вставляем внутрь
      int braceLevel = 0;
      int endIndex = -1;
      for (var i = pluginsIndex; i < content.length; i++) {
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

      if (endIndex != -1) {
        final before = content.substring(0, endIndex);
        final after = content.substring(endIndex);
        const huaweiPluginLine = '\n    id("com.huawei.agconnect")';
        content = '$before$huaweiPluginLine$after';
        changed = true;
        print('✅ Добавлен плагин com.huawei.agconnect в app/build.gradle.kts');
      }
    } else {
      // Нет блока plugins – создаём его в начале файла
      const pluginsBlock = '''
plugins {
    id("com.huawei.agconnect")
}

''';
      content = pluginsBlock + content;
      changed = true;
      print('✅ Создан блок plugins с com.huawei.agconnect в app/build.gradle.kts');
    }
  } else {
    print(
      'ℹ️  Плагин com.huawei.agconnect уже присутствует в app/build.gradle.kts',
    );
  }

  if (changed) {
    buildFile.writeAsStringSync(content);
  }

  // buildTypes с ProGuard для release/debug
  _setupHuaweiBuildTypes(androidPath);

  // dependencies с play-services-location и installreferrer
  _setupHuaweiAppDependencies(androidPath);
}

/// Добавляет необходимые элементы Huawei в AndroidManifest.xml приложения.
void setupHuaweiAndroidManifest(String androidPath) {
  final manifestFile = File('$androidPath/app/src/main/AndroidManifest.xml');
  if (!manifestFile.existsSync()) {
    print('⚠️  AndroidManifest.xml не найден, пропускаю Huawei-манифест');
    return;
  }

  var content = manifestFile.readAsStringSync();

  // --- Блоки внутри <application> ---

  // Если уже есть признак Huawei push — блоки внутри application не добавляем
  final hasHuaweiReceivers = content.contains(
    'com.huawei.hms.flutter.push.receiver.BackgroundMessageBroadcastReceiver',
  );

  const huaweiApplicationBlock = '''
        <meta-data android:name="push_kit_auto_init_enabled" android:value="true" />
        <receiver android:name="com.huawei.hms.flutter.push.receiver.local.HmsLocalNotificationBootEventReceiver" android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
        </receiver>
        <receiver android:name="com.huawei.hms.flutter.push.receiver.local.HmsLocalNotificationScheduledPublisher" android:exported="false" />
        <receiver android:name="com.huawei.hms.flutter.push.receiver.BackgroundMessageBroadcastReceiver" android:exported="false">
            <intent-filter>
                <action android:name="com.huawei.hms.flutter.push.receiver.BACKGROUND_REMOTE_MESSAGE" />
            </intent-filter>
        </receiver>
''';

  if (!hasHuaweiReceivers) {
    final appCloseIndex = content.indexOf('</application>');
    if (appCloseIndex == -1) {
      print(
        '⚠️  Тег </application> не найден в AndroidManifest.xml, пропускаю Huawei <application>-элементы',
      );
    } else {
      final buffer = StringBuffer()
        ..write(content.substring(0, appCloseIndex))
        ..write(huaweiApplicationBlock)
        ..write(content.substring(appCloseIndex));
      content = buffer.toString();
      print('✅ Добавлены Huawei элементы в <application> AndroidManifest.xml');
    }
  } else {
    print('ℹ️  Huawei элементы уже присутствуют в <application>');
  }

  // --- Блок <queries> с Huawei AIDL service ---

  const huaweiQueriesBlock = '''
    <queries>
        <intent>
            <action android:name="com.huawei.hms.core.aidlservice" />
        </intent>
    </queries>
''';

  if (!content.contains('com.huawei.hms.core.aidlservice')) {
    // Если уже есть блок <queries> – добавляем внутрь него новый <intent>
    final queriesStart = content.indexOf('<queries>');
    final queriesEnd = content.indexOf('</queries>');

    if (queriesStart != -1 && queriesEnd != -1 && queriesEnd > queriesStart) {
      final insertIndex = queriesEnd;
      final buffer = StringBuffer()
        ..write(content.substring(0, insertIndex))
        ..write('''

        <intent>
            <action android:name="com.huawei.hms.core.aidlservice" />
        </intent>
''')
        ..write(content.substring(insertIndex));
      content = buffer.toString();
      print(
        '✅ Добавлен Huawei intent в существующий <queries> AndroidManifest.xml',
      );
    } else {
      // Иначе добавляем новый блок <queries> перед </manifest>
      final manifestCloseIndex = content.indexOf('</manifest>');
      if (manifestCloseIndex == -1) {
        print(
          '⚠️  Тег </manifest> не найден в AndroidManifest.xml, пропускаю Huawei <queries>',
        );
      } else {
        final buffer = StringBuffer()
          ..write(content.substring(0, manifestCloseIndex))
          ..write('\n')
          ..write(huaweiQueriesBlock)
          ..write(content.substring(manifestCloseIndex));
        content = buffer.toString();
        print('✅ Добавлен Huawei <queries> в AndroidManifest.xml');
      }
    }
  } else {
    print(
      'ℹ️  Huawei intent для com.huawei.hms.core.aidlservice уже есть в <queries>',
    );
  }

  manifestFile.writeAsStringSync(content);
}

/// Гарантирует, что блок buildTypes для Huawei в app/build.gradle.kts
/// имеет строго нужный нам вид (release+debug с ProGuard).
void _setupHuaweiBuildTypes(String androidPath) {
  final buildFile = File('$androidPath/app/build.gradle.kts');
  if (!buildFile.existsSync()) {
    return;
  }

  const fullBuildTypesBlock = '''
buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android.txt"),
            "proguard-rules.pro"
        )
    }

    getByName("debug") {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        isDebuggable = true
        proguardFiles(
            getDefaultProguardFile("proguard-android.txt"),
            "proguard-rules.pro"
        )
    }
}
''';

  var content = buildFile.readAsStringSync();

  // Если buildTypes уже есть – ПОЛНОСТЬЮ заменяем его на нужный вид
  final buildTypesStart = content.indexOf('buildTypes {');
  if (buildTypesStart != -1) {
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
    print('✅ Блок buildTypes приведён к нужному виду для Huawei');
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
    ..write('\n')
    ..write(fullBuildTypesBlock)
    ..write(content.substring(insertIndex));

  buildFile.writeAsStringSync(buffer.toString());
  print('✅ Добавлен блок buildTypes для Huawei в app/build.gradle.kts');
}

/// Добавляет необходимые implementation-зависимости в dependencies.
void _setupHuaweiAppDependencies(String androidPath) {
  final buildFile = File('$androidPath/app/build.gradle.kts');
  if (!buildFile.existsSync()) {
    return;
  }

  var content = buildFile.readAsStringSync();

  const locationDep =
      'implementation("com.google.android.gms:play-services-location:21.3.0")';
  const installReferrerDep =
      'implementation("com.android.installreferrer:installreferrer:2.2")';

  final hasLocation = content.contains(locationDep);
  final hasInstallReferrer = content.contains(installReferrerDep);

  if (hasLocation && hasInstallReferrer) {
    print(
      'ℹ️  Зависимости play-services-location и installreferrer уже присутствуют',
    );
    return;
  }

  final depsIndex = content.indexOf('dependencies {');
  if (depsIndex == -1) {
    // Создаём новый блок dependencies в конце файла
    final buffer = StringBuffer()
      ..write(content.trimRight())
      ..write('''

dependencies {
    $locationDep
    $installReferrerDep
}
''');

    buildFile.writeAsStringSync(buffer.toString());
    print('✅ Создан блок dependencies в app/build.gradle.kts');
    return;
  }

  // Вставляем перед закрывающей скобкой блока dependencies (по балансу скобок)
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
    return;
  }

  final buffer = StringBuffer()..write(content.substring(0, closingIndex));

  if (!hasLocation) {
    buffer.write('\n    $locationDep');
  }
  if (!hasInstallReferrer) {
    buffer.write('\n    $installReferrerDep');
  }

  buffer
    ..write('\n')
    ..write(content.substring(closingIndex));

  buildFile.writeAsStringSync(buffer.toString());
  print(
    '✅ Добавлены зависимости play-services-location и installreferrer в app/build.gradle.kts',
  );
}

void setupHuaweiPubspec(String projectPath) {
  final pubspecFile = File('$projectPath/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('⚠️  Предупреждение: pubspec.yaml не найден, пропускаю...');
    return;
  }

  final lines = pubspecFile.readAsLinesSync();
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
        '⚠️  Не удалось найти секцию environment в pubspec.yaml, пропускаю добавление Huawei зависимостей',
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

  // Определяем, какие зависимости уже есть
  bool hasPush = lines.any((l) => l.trimLeft().startsWith('huawei_push:'));
  bool hasAds = lines.any((l) => l.trimLeft().startsWith('huawei_ads:'));

  // Добавляем недостающие блоки подряд (availability добавляем отдельно только
  // при выборе "оба провайдера" в общем setup-скрипте)
  final toInsert = <String>[];

  if (!hasPush) {
    toInsert.addAll(const [
      '  huawei_push:',
      '    git:',
      '      url: https://github.com/norutplz/hms-flutter-plugin.git',
      '      ref: hms_push_flutter_3.29',
      '      path: flutter-hms-push',
      '',
    ]);
    print('✅ Добавлена зависимость huawei_push в pubspec.yaml');
    changed = true;
  } else {
    print('ℹ️  Зависимость huawei_push уже присутствует в pubspec.yaml');
  }

  if (!hasAds) {
    toInsert.addAll(const [
      '  huawei_ads:',
      '    git:',
      '      url: https://github.com/norutplz/hms-flutter-plugin.git',
      '      ref: hms_push_flutter_3.29',
      '      path: flutter-hms-ads',
      '',
    ]);
    print('✅ Добавлена зависимость huawei_ads в pubspec.yaml');
    changed = true;
  } else {
    print('ℹ️  Зависимость huawei_ads уже присутствует в pubspec.yaml');
  }

  if (changed && toInsert.isNotEmpty) {
    lines.insertAll(insertIndex, toInsert);
    pubspecFile.writeAsStringSync(lines.join('\n'));
  }
}
