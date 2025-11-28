// Очистка Android-проекта от настроек провайдеров (Google/Huawei)

import 'dart:io';

/// Очищает Android-проект от настроек обоих провайдеров (Google/Huawei).
///
/// Вызывается в начале сценариев установки, чтобы не было конфликтов,
/// после чего выбираемый провайдер добавляет только недостающее.
void cleanAndroidProject(String androidPath) {
  _cleanSettingsFiles(androidPath);
  _cleanRootBuildGradle(androidPath);
  _cleanAppBuildGradle(androidPath);
  _cleanAndroidManifest(androidPath);
  _cleanProguardRules(androidPath);
}

/// Очищает pubspec.yaml от зависимостей, которые добавляют провайдеры.
void cleanPubspec(String projectPath) {
  final pubspecFile = File('$projectPath/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    return;
  }

  final lines = pubspecFile.readAsLinesSync();
  final result = <String>[];
  bool changed = false;

  // Префиксы зависимостей, которые мы добавляем скриптом
  const depPrefixes = <String>[
    'firebase_core:',
    'firebase_remote_config:',
    'firebase_messaging:',
    'firebase_analytics:',
    'firebase_crashlytics:',
    'huawei_push:',
    'huawei_ads:',
    'huawei_hmsavailability:',
  ];

  int i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trimLeft();

    final shouldRemove = depPrefixes.any((p) => trimmed.startsWith(p));

    if (shouldRemove) {
      changed = true;

      // Пропускаем саму строку зависимости и все вложенные строки git-блока.
      i++;
      while (i < lines.length) {
        final next = lines[i];
        final nextTrimmed = next.trimLeft();

        if (nextTrimmed.isEmpty) {
          // Пустые строки считаем частью блока
          i++;
          continue;
        }

        // Строка с отступом в 4+ пробела — вложенный блок (git:, url:, path: и т.п.)
        if (next.startsWith('    ')) {
          i++;
          continue;
        }

        // Строка с отступом ровно в 2 пробела и не пустая — это уже следующая
        // зависимость уровня dependencies:, её не трогаем.
        if (next.startsWith('  ')) {
          break;
        }

        // Всё что без отступа — новая секция (dev_dependencies:, flutter: и т.п.)
        break;
      }

      continue;
    }

    result.add(line);
    i++;
  }

  if (changed) {
    pubspecFile.writeAsStringSync(result.join('\n'));
    print('✅ Очищены провайдерские зависимости в pubspec.yaml');
  }
}

void _cleanSettingsFiles(String androidPath) {
  for (final name in ['settings.gradle.kts', 'settings.gradle']) {
    final file = File('$androidPath/$name');
    if (!file.existsSync()) continue;

    var content = file.readAsStringSync();
    final original = content;

    // Удаляем Google плагины
    content = content.replaceAll(
      RegExp(r'''\s*id\("com\.google\.gms\.google-services"\).*?apply false'''),
      '',
    );
    content = content.replaceAll(
      RegExp(
        r'''\s*id\("com\.google\.firebase\.crashlytics"\).*?apply false''',
      ),
      '',
    );
    content = content.replaceAll(
      RegExp(r"""\s*id 'com\.google\.gms\.google-services'.*?apply false"""),
      '',
    );
    content = content.replaceAll(
      RegExp(r"""\s*id 'com\.google\.firebase\.crashlytics'.*?apply false"""),
      '',
    );

    // Удаляем Huawei plugin и только наше правило в resolutionStrategy — целыми строками
    content = content.replaceAll(
      RegExp(
        r'''^.*id\("com\.huawei\.agconnect"\).*?apply false.*\n?''',
        multiLine: true,
      ),
      '',
    );
    content = content.replaceAll(
      RegExp(
        r'''^.*if\s*\(\s*requested\.id\.id\s*==\s*"com\.huawei\.agconnect"\s*\)\s*\{\s*useModule\("com\.huawei\.agconnect:agcp:1\.9\.1\.303"\)\s*}.*\n?''',
        multiLine: true,
      ),
      '',
    );

    // Удаляем строку Huawei репозитория в pluginManagement.repositories целиком
    content = content.replaceAll(
      RegExp(
        r'''^.*maven\s*\{\s*url\s*=\s*uri\("https://developer\.huawei\.com/repo/"\)\s*}.*\n?''',
        multiLine: true,
      ),
      '',
    );
    content = content.replaceAll(
      RegExp(
        r'''^.*maven\s*\{\s*url\s+['"]https://developer\.huawei\.com/repo/['"]\s*}.*\n?''',
        multiLine: true,
      ),
      '',
    );

    if (content != original) {
      file.writeAsStringSync(content);
      print('✅ Очищены провайдерские настройки в $name');
    }
  }
}

void _cleanRootBuildGradle(String androidPath) {
  final rootKts = File('$androidPath/build.gradle.kts');
  if (!rootKts.existsSync()) return;

  var content = rootKts.readAsStringSync();
  final original = content;

  // Удаляем наш buildscript блок с Huawei agconnect/agcp
  content = content.replaceAll(
    RegExp(
      r'''buildscript\s*\{\s*repositories\s*\{[\s\S]*?gradlePluginPortal\(\)\s*}[\s\S]*?dependencies\s*\{[\s\S]*?classpath\("com\.huawei\.agconnect:agcp:1\.9\.1\.303"\)[\s\S]*?}[\s\S]*?}''',
    ),
    '',
  );

  // Удаляем Huawei репозиторий в allprojects.repositories
  content = content.replaceAll(
    RegExp(r'''\s*maven\(url\s*=\s*"https://developer\.huawei\.com/repo/"\)'''),
    '',
  );

  if (content != original) {
    rootKts.writeAsStringSync(content);
    print('✅ Очищены Huawei настройки в build.gradle.kts');
  }
}

void _cleanAppBuildGradle(String androidPath) {
  for (final name in ['app/build.gradle.kts', 'app/build.gradle']) {
    final file = File('$androidPath/$name');
    if (!file.existsSync()) continue;

    var content = file.readAsStringSync();
    final original = content;

    // --- PLUGINS ---
    content = content.replaceAll(
      RegExp(r'''\s*id\("com\.google\.gms\.google-services"\)\s*'''),
      '',
    );
    content = content.replaceAll(
      RegExp(r'''\s*id\("com\.google\.firebase\.crashlytics"\)\s*'''),
      '',
    );
    content = content.replaceAll(
      RegExp(r"""\s*id 'com\.google\.gms\.google-services'\s*"""),
      '',
    );
    content = content.replaceAll(
      RegExp(r"""\s*id 'com\.google\.firebase\.crashlytics'\s*"""),
      '',
    );
    content = content.replaceAll(
      RegExp(r'''\s*id\("com\.huawei\.agconnect"\)\s*'''),
      '',
    );

    // --- DEPENDENCIES (общие для Google/Huawei) ---
    content = content.replaceAll(
      RegExp(
        r'''\s*implementation\("com\.google\.android\.gms:play-services-location:21\.3\.0"\)\s*''',
      ),
      '',
    );
    content = content.replaceAll(
      RegExp(
        r'''\s*implementation\("com\.android\.installreferrer:installreferrer:2\.2"\)\s*''',
      ),
      '',
    );
    content = content.replaceAll(
      RegExp(
        r'''\s*implementation "com\.google\.android\.gms:play-services-location:21\.3\.0"\s*''',
      ),
      '',
    );
    content = content.replaceAll(
      RegExp(
        r'''\s*implementation "com\.android\.installreferrer:installreferrer:2\.2"\s*''',
      ),
      '',
    );

    // --- BUILDTYPES: для KTS возвращаем дефолтный Flutter-блок ---
    if (name.endsWith('.kts')) {
      const defaultBuildTypesBlock = '''
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
''';

      final buildTypesIndex = content.indexOf('buildTypes {');
      if (buildTypesIndex != -1) {
        int braceLevel = 0;
        int endIndex = -1;
        for (var i = buildTypesIndex; i < content.length; i++) {
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
          final before = content.substring(0, buildTypesIndex);
          final after = content.substring(endIndex + 1);
          content = before + defaultBuildTypesBlock + after;
        }
      }
    }

    if (content != original) {
      file.writeAsStringSync(content);
      print('✅ Очищены провайдерские настройки в $name');
    }
  }
}

void _cleanAndroidManifest(String androidPath) {
  final manifest = File('$androidPath/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) return;

  var content = manifest.readAsStringSync();
  final original = content;

  // Firebase meta-data
  content = content.replaceAll(
    RegExp(
      r'''\s*<meta-data android:name="com\.google\.firebase\.messaging\.default_notification_icon" android:resource="@drawable/firebase_icon_push"\s*/>\s*''',
    ),
    '',
  );

  // Huawei блок внутри <application>
  content = content.replaceAll(
    RegExp(
      r'\s*<meta-data android:name="push_kit_auto_init_enabled"[\s\S]*?com\.huawei\.hms\.flutter\.push\.receiver\.BACKGROUND_REMOTE_MESSAGE"[\s\S]*?</receiver>',
    ),
    '',
  );

  // Huawei queries / intent
  // 1) Удаляем наш отдельный блок <queries> (если он был добавлен в конце манифеста)
  const huaweiQueriesBlock = '''
    <queries>
        <intent>
            <action android:name="com.huawei.hms.core.aidlservice" />
        </intent>
    </queries>
''';
  if (content.contains('com.huawei.hms.core.aidlservice')) {
    content = content.replaceAll(huaweiQueriesBlock, '');

    // 2) Если наш intent был вставлен внутрь уже существующего <queries>,
    //    удаляем только сам <intent> с Huawei-экшеном, не трогая остальное.
    content = content.replaceAll(
      RegExp(
        r'\s*<intent>\s*<action android:name="com\.huawei\.hms\.core\.aidlservice"\s*/>\s*</intent>',
      ),
      '',
    );
  }

  if (content != original) {
    manifest.writeAsStringSync(content);
    print('✅ Очищены провайдерские элементы в AndroidManifest.xml');
  }
}

void _cleanProguardRules(String androidPath) {
  final proguard = File('$androidPath/app/proguard-rules.pro');
  if (!proguard.existsSync()) return;

  var content = proguard.readAsStringSync();
  final original = content;

  // Удаляем наш блок Huawei (по маркерам)
  content = content.replaceAll(
    RegExp(r'-ignorewarnings[\s\S]*?-repackageclasses'),
    '',
  );

  if (content != original) {
    proguard.writeAsStringSync(content.trimRight() + '\n');
    print('✅ Очищены Huawei правила в app/proguard-rules.pro');
  }
}
