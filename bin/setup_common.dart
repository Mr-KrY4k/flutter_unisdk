// Общие функции для настройки провайдеров

import 'dart:io';

/// Находит путь к корню плагина
/// Сначала пытается найти через зависимость в pubspec.yaml проекта,
/// затем через путь к скрипту, затем через pub cache
String findPluginPath() {
  // СТРАТЕГИЯ 1: Ищем плагин через зависимость в pubspec.yaml проекта
  // Это самый надежный способ, т.к. использует реальную зависимость проекта
  final currentDir = Directory.current;
  final projectPubspec = File('${currentDir.path}/pubspec.yaml');

  if (projectPubspec.existsSync()) {
    final content = projectPubspec.readAsStringSync();
    final lines = content.split('\n');

    bool inFlutterUnisdk = false;
    String? pathValue;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimLeft();

      // Ищем начало зависимости flutter_unisdk
      if (line.startsWith('flutter_unisdk:')) {
        inFlutterUnisdk = true;
        // Проверяем, не указан ли path на той же строке
        if (line.contains('path:')) {
          final pathMatch = RegExp(r'path:\s*(.+)').firstMatch(line);
          if (pathMatch != null) {
            pathValue = pathMatch.group(1)?.trim();
          }
        }
        continue;
      }

      if (inFlutterUnisdk) {
        // Если встретили новую зависимость - выходим
        if (line.isNotEmpty &&
            !line.startsWith('#') &&
            !line.startsWith(' ') &&
            !line.startsWith('\t') &&
            line.contains(':')) {
          break;
        }

        // Ищем path: в зависимостях
        if (line.startsWith('path:')) {
          final pathMatch = RegExp(r'path:\s*(.+)').firstMatch(line);
          if (pathMatch != null) {
            pathValue = pathMatch.group(1)?.trim();
          }
        }
      }
    }

    if (pathValue != null) {
      // path может быть относительным (../) или абсолютным
      final pluginPath = pathValue.startsWith('/')
          ? pathValue
          : '${currentDir.path}/$pathValue';

      final resolvedPath = Directory(pluginPath).resolveSymbolicLinksSync();
      final pluginPubspec = File('$resolvedPath/pubspec.yaml');

      if (pluginPubspec.existsSync()) {
        final pluginContent = pluginPubspec.readAsStringSync();
        if (pluginContent.contains('name: flutter_unisdk')) {
          return resolvedPath;
        }
      }
    }
  }

  // СТРАТЕГИЯ 2: Ищем плагин через pub cache (для git зависимостей)
  // Это работает, когда плагин установлен через git или pub.dev
  try {
    // Используем flutter pub cache list для поиска плагина
    final result = Process.runSync('flutter', ['pub', 'cache', 'list']);

    if (result.exitCode == 0) {
      final output = result.stdout.toString();
      final lines = output.split('\n');

      for (final line in lines) {
        if (line.contains('flutter_unisdk')) {
          // Формат: flutter_unisdk 0.0.1 /path/to/cache
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 3) {
            final cachePath = parts[2];
            final pluginPubspec = File('$cachePath/pubspec.yaml');
            if (pluginPubspec.existsSync()) {
              final content = pluginPubspec.readAsStringSync();
              if (content.contains('name: flutter_unisdk')) {
                return cachePath;
              }
            }
          }
        }
      }
    }
  } catch (e) {
    // Игнорируем ошибки, пробуем другие способы
  }

  // СТРАТЕГИЯ 3: Ищем плагин через путь к скрипту
  final scriptUri = Platform.script;
  String? scriptPath;

  if (scriptUri.scheme == 'package') {
    // Если это package: URI (dart run flutter_unisdk:setup),
    // используем pub cache для поиска
    // Это уже обработано в СТРАТЕГИИ 2
  } else {
    scriptPath = scriptUri.toFilePath();
  }

  // Если путь к скрипту найден, пытаемся найти плагин от него
  if (scriptPath != null) {
    final scriptFile = File(scriptPath);

    // Если скрипт находится в bin/, то корень плагина на уровень выше
    if (scriptPath.contains('/bin/')) {
      final binDir = scriptFile.parent;
      final pluginPath = binDir.parent.path;
      final pluginPubspec = File('$pluginPath/pubspec.yaml');
      if (pluginPubspec.existsSync()) {
        final content = pluginPubspec.readAsStringSync();
        if (content.contains('name: flutter_unisdk')) {
          return pluginPath;
        }
      }
    }

    // Пытаемся найти плагин, идя вверх от скрипта
    var currentDir = scriptFile.parent;
    for (int i = 0; i < 10; i++) {
      final pubspecFile = File('${currentDir.path}/pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final content = pubspecFile.readAsStringSync();
        if (content.contains('name: flutter_unisdk')) {
          return currentDir.path;
        }
      }
      if (currentDir.path == currentDir.parent.path) {
        break;
      }
      currentDir = currentDir.parent;
    }
  }

  // СТРАТЕГИЯ 3: Пытаемся найти через pub cache
  try {
    final result = Process.runSync('flutter', ['pub', 'cache', 'list']);

    if (result.exitCode == 0) {
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.contains('flutter_unisdk')) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            return parts[1];
          }
        }
      }
    }
  } catch (e) {
    // Игнорируем ошибки
  }

  // СТРАТЕГИЯ 4: Пытаемся найти плагин, идя вверх от текущей директории
  var searchDir = Directory.current;
  for (int i = 0; i < 10; i++) {
    final pubspecFile = File('${searchDir.path}/pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = pubspecFile.readAsStringSync();
      if (content.contains('name: flutter_unisdk')) {
        return searchDir.path;
      }
    }
    if (searchDir.path == searchDir.parent.path) {
      break;
    }
    searchDir = searchDir.parent;
  }

  throw Exception(
    'Не удалось найти плагин flutter_unisdk. '
    'Убедитесь, что плагин добавлен в pubspec.yaml проекта или установлен через pub cache.',
  );
}

/// Читает зависимости из pubspec.yaml плагина и возвращает их в виде Map
/// Ключ - имя зависимости, значение - либо строка версии, либо Map с git-блоком
Map<String, dynamic> readPluginDependencies() {
  final pluginPath = findPluginPath();
  final pluginPubspec = File('$pluginPath/pubspec.yaml');

  if (!pluginPubspec.existsSync()) {
    throw Exception('pubspec.yaml плагина не найден по пути: $pluginPath');
  }

  final lines = pluginPubspec.readAsLinesSync();
  final dependencies = <String, dynamic>{};
  bool inDependencies = false;
  String? currentDep;
  Map<String, String>? currentGitBlock;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();

    if (trimmed == 'dependencies:') {
      inDependencies = true;
      continue;
    }

    if (inDependencies) {
      // Если встретили новую секцию (не пустая строка, начинается не с пробела)
      if (trimmed.isNotEmpty &&
          !line.startsWith(' ') &&
          !line.startsWith('\t')) {
        if (trimmed != 'dependencies:') {
          break;
        }
      }

      // Пропускаем комментарии
      if (trimmed.startsWith('#')) {
        continue;
      }

      // Если строка начинается с зависимости (например, "firebase_core: ^4.0.0")
      if (trimmed.contains(':') && line.startsWith('  ')) {
        final colonIndex = trimmed.indexOf(':');
        final depName = trimmed.substring(0, colonIndex).trim();
        final depValue = trimmed.substring(colonIndex + 1).trim();

        // Если это простая зависимость с версией
        if (depValue.isNotEmpty) {
          dependencies[depName] = depValue;
          currentDep = null;
          currentGitBlock = null;
        } else {
          // Это начало git-блока или другой структуры
          currentDep = depName;
          currentGitBlock = <String, String>{};
        }
      } else if (currentDep != null && line.trim().isNotEmpty) {
        // Читаем git-блок
        if (trimmed.startsWith('git:')) {
          // Пропускаем строку "git:"
          continue;
        } else if (trimmed.startsWith('url:') ||
            trimmed.startsWith('ref:') ||
            trimmed.startsWith('path:')) {
          final colonIndex = trimmed.indexOf(':');
          final key = trimmed.substring(0, colonIndex).trim();
          final value = trimmed.substring(colonIndex + 1).trim();
          currentGitBlock![key] = value;
        } else if (trimmed.isEmpty ||
            (trimmed.contains(':') &&
                !trimmed.startsWith('url:') &&
                !trimmed.startsWith('ref:') &&
                !trimmed.startsWith('path:') &&
                !trimmed.startsWith('git:'))) {
          // Конец git-блока - сохраняем
          if (currentGitBlock != null && currentGitBlock.isNotEmpty) {
            dependencies[currentDep] = {'git': currentGitBlock};
          }
          currentDep = null;
          currentGitBlock = null;
        }
      }
    }
  }

  // Сохраняем последний git-блок, если он был
  if (currentDep != null &&
      currentGitBlock != null &&
      currentGitBlock.isNotEmpty) {
    dependencies[currentDep] = {'git': currentGitBlock};
  }

  return dependencies;
}

/// Переносит зависимости в приложение в зависимости от провайдера
/// Список зависимостей для каждого провайдера задан здесь в коде
/// Добавляйте сюда новые зависимости по мере необходимости
void transferDependenciesToProject(String projectPath, String provider) {
  final projectPubspec = File('$projectPath/pubspec.yaml');

  if (!projectPubspec.existsSync()) {
    throw Exception('pubspec.yaml проекта не найден по пути: $projectPath');
  }

  // Список зависимостей для каждого провайдера с версиями
  // Формат: Map<имя_зависимости, значение> где значение может быть строкой версии или Map с git-блоком
  final dependencies = <String, dynamic>{};

  if (provider == 'google') {
    dependencies.addAll({
      'firebase_core': '^4.0.0',
      'firebase_remote_config': '^6.0.0',
      'firebase_messaging': '^16.0.0',
      'firebase_analytics': '^12.0.0',
      'firebase_crashlytics': '^5.0.0',
    });
  } else if (provider == 'huawei') {
    dependencies.addAll({
      'huawei_push': {
        'git': {
          'url': 'https://github.com/norutplz/hms-flutter-plugin.git',
          'ref': 'hms_push_flutter_3.29',
          'path': 'flutter-hms-push',
        },
      },
      'huawei_ads': {
        'git': {
          'url': 'https://github.com/norutplz/hms-flutter-plugin.git',
          'ref': 'hms_push_flutter_3.29',
          'path': 'flutter-hms-ads',
        },
      },
    });
  } else if (provider == 'both') {
    dependencies.addAll({
      'firebase_core': '^4.0.0',
      'firebase_remote_config': '^6.0.0',
      'firebase_messaging': '^16.0.0',
      'firebase_analytics': '^12.0.0',
      'firebase_crashlytics': '^5.0.0',
      'huawei_push': {
        'git': {
          'url': 'https://github.com/norutplz/hms-flutter-plugin.git',
          'ref': 'hms_push_flutter_3.29',
          'path': 'flutter-hms-push',
        },
      },
      'huawei_ads': {
        'git': {
          'url': 'https://github.com/norutplz/hms-flutter-plugin.git',
          'ref': 'hms_push_flutter_3.29',
          'path': 'flutter-hms-ads',
        },
      },
      'huawei_hmsavailability': {
        'git': {
          'url': 'https://github.com/norutplz/hms-flutter-plugin.git',
          'ref': 'hms_push_flutter_3.29',
          'path': 'flutter-hms-availability',
        },
      },
    });
  }

  final lines = projectPubspec.readAsLinesSync();
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
      throw Exception('Не удалось найти секцию environment в pubspec.yaml');
    }
  }

  // Определяем место вставки внутри блока dependencies
  // Ищем конец блока dependencies (первую строку, которая не начинается с пробела или табуляции)
  int insertIndex = depsIndex + 1;
  while (insertIndex < lines.length) {
    final line = lines[insertIndex];
    final trimmed = line.trimLeft();

    // Если строка пустая или комментарий - пропускаем
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      insertIndex++;
      continue;
    }

    // Если строка начинается с пробела/табуляции - это зависимость внутри блока
    if (line.startsWith('  ') || line.startsWith('\t')) {
      insertIndex++;
      continue;
    }

    // Если строка не начинается с пробела - это конец блока dependencies
    break;
  }

  // Для каждой зависимости проверяем и добавляем/обновляем
  for (final entry in dependencies.entries) {
    final depName = entry.key;
    final depValue = entry.value;

    // Ищем существующую строку для этой зависимости
    final existingIndex = lines.indexWhere(
      (l) => l.trimLeft().startsWith('$depName:'),
    );

    if (existingIndex != -1) {
      // Зависимость уже есть - проверяем, нужно ли обновить
      if (depValue is String) {
        // Простая зависимость с версией
        final newLine = '  $depName: $depValue';
        if (lines[existingIndex].trim() != newLine.trim()) {
          // Проверяем, не является ли это git-блоком
          int gitBlockEnd = existingIndex;
          for (int i = existingIndex + 1; i < lines.length; i++) {
            if (lines[i].trim().isEmpty ||
                (lines[i].trimLeft().startsWith(RegExp(r'^[a-z_]+:')) &&
                    !lines[i].trimLeft().startsWith('git:') &&
                    !lines[i].trimLeft().startsWith('url:') &&
                    !lines[i].trimLeft().startsWith('ref:') &&
                    !lines[i].trimLeft().startsWith('path:'))) {
              break;
            }
            gitBlockEnd = i;
          }

          // Удаляем старый блок и вставляем новый
          lines.removeRange(existingIndex, gitBlockEnd + 1);
          lines.insert(existingIndex, newLine);
          changed = true;
        }
      } else if (depValue is Map && depValue.containsKey('git')) {
        // Git-блок - проверяем, нужно ли обновить
        final gitBlock = depValue['git'] as Map<String, dynamic>;
        int gitBlockEnd = existingIndex;
        for (int i = existingIndex + 1; i < lines.length; i++) {
          if (lines[i].trim().isEmpty ||
              (lines[i].trimLeft().startsWith(RegExp(r'^[a-z_]+:')) &&
                  !lines[i].trimLeft().startsWith('git:') &&
                  !lines[i].trimLeft().startsWith('url:') &&
                  !lines[i].trimLeft().startsWith('ref:') &&
                  !lines[i].trimLeft().startsWith('path:'))) {
            break;
          }
          gitBlockEnd = i;
        }

        // Проверяем, совпадает ли git-блок
        bool needsUpdate = false;
        final existingBlock = lines
            .sublist(existingIndex, gitBlockEnd + 1)
            .join('\n');
        final expectedUrl = gitBlock['url']?.toString() ?? '';
        final expectedRef = gitBlock['ref']?.toString() ?? '';
        final expectedPath = gitBlock['path']?.toString() ?? '';

        if (!existingBlock.contains(expectedUrl) ||
            !existingBlock.contains(expectedRef) ||
            (expectedPath.isNotEmpty &&
                !existingBlock.contains(expectedPath))) {
          needsUpdate = true;
        }

        if (needsUpdate) {
          // Удаляем старый блок
          lines.removeRange(existingIndex, gitBlockEnd + 1);

          // Вставляем новый git-блок
          lines.insert(existingIndex, '  $depName:');
          int insertPos = existingIndex + 1;
          lines.insert(insertPos, '    git:');
          insertPos++;
          if (gitBlock.containsKey('url')) {
            lines.insert(insertPos, '      url: ${gitBlock['url']}');
            insertPos++;
          }
          if (gitBlock.containsKey('ref')) {
            lines.insert(insertPos, '      ref: ${gitBlock['ref']}');
            insertPos++;
          }
          if (gitBlock.containsKey('path')) {
            lines.insert(insertPos, '      path: ${gitBlock['path']}');
            insertPos++;
          }
          lines.insert(insertPos, '');
          changed = true;
        }
      }
      continue;
    }

    // Зависимости нет - добавляем
    if (depValue is String) {
      // Простая зависимость с версией
      lines.insert(insertIndex, '  $depName: $depValue');
      insertIndex++;
      changed = true;
    } else if (depValue is Map && depValue.containsKey('git')) {
      // Git-блок
      final gitBlock = depValue['git'] as Map<String, dynamic>;
      lines.insert(insertIndex, '  $depName:');
      insertIndex++;
      lines.insert(insertIndex, '    git:');
      insertIndex++;
      if (gitBlock.containsKey('url')) {
        lines.insert(insertIndex, '      url: ${gitBlock['url']}');
        insertIndex++;
      }
      if (gitBlock.containsKey('ref')) {
        lines.insert(insertIndex, '      ref: ${gitBlock['ref']}');
        insertIndex++;
      }
      if (gitBlock.containsKey('path')) {
        lines.insert(insertIndex, '      path: ${gitBlock['path']}');
        insertIndex++;
      }
      lines.insert(insertIndex, '');
      insertIndex++;
      changed = true;
    }
  }

  if (changed) {
    projectPubspec.writeAsStringSync(lines.join('\n'));
    print('✅ Добавлены зависимости в pubspec.yaml для провайдера: $provider');
  }
}
