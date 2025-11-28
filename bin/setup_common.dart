// Общие функции для настройки провайдеров

import 'dart:io';

/// Находит путь к корню плагина
String findPluginPath() {
  // Получаем путь к текущему скрипту
  final scriptUri = Platform.script;

  // Если это package: URI, пытаемся найти через pub cache
  if (scriptUri.scheme == 'package') {
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
  } else {
    // Это файловый путь
    final scriptPath = scriptUri.toFilePath();
    final scriptFile = File(scriptPath);

    // Если скрипт находится в bin/, то корень плагина на уровень выше
    if (scriptPath.contains('/bin/')) {
      final binDir = scriptFile.parent;
      return binDir.parent.path;
    }

    // Если скрипт находится в tool/, то корень плагина на уровень выше
    if (scriptPath.contains('/tool/')) {
      final toolDir = scriptFile.parent;
      return toolDir.parent.path;
    }
  }

  // Пытаемся найти через pub cache
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

  // По умолчанию используем текущую директорию
  return Directory.current.path;
}

/// Устанавливает провайдер в gradle.properties плагина
void setProviderInPlugin(String provider) {
  final pluginPath = findPluginPath();
  final pluginGradleProps = File('$pluginPath/android/gradle.properties');

  if (!pluginGradleProps.existsSync()) {
    print('⚠️  gradle.properties плагина не найден, создаю...');
    pluginGradleProps.createSync(recursive: true);
  }

  String content = pluginGradleProps.readAsStringSync();

  // Обновляем или добавляем провайдер
  if (content.contains('unisdk.provider=')) {
    content = content.replaceFirst(
      RegExp(r'unisdk\.provider=.*'),
      'unisdk.provider=$provider',
    );
  } else {
    content +=
        '\n# Провайдер сервисов: huawei, google, both\nunisdk.provider=$provider\n';
  }

  pluginGradleProps.writeAsStringSync(content);
  print('✅ Установлен провайдер: $provider в плагине');
}
