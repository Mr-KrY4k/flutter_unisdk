#!/usr/bin/env dart
// Универсальный интерактивный скрипт настройки провайдеров

import 'dart:io';
import 'setup_huawei.dart' as huawei;
import 'setup_google.dart' as google;
import 'cleanup_android.dart';

void main(List<String> args) {
  // Всегда используем текущую директорию как путь к проекту
  final projectPath = Directory.current.path;
  final androidPath = '$projectPath/android';

  if (!Directory(androidPath).existsSync()) {
    print('❌ Ошибка: Папка android не найдена');
    print('   Убедитесь, что вы находитесь в корне Flutter проекта');
    exit(1);
  }

  // Выбор провайдера
  print('');
  print('🔧 Настройка flutter_unisdk для проекта: $projectPath');
  print('');
  print('Выберите действие:');
  print('  1. Настроить Huawei Mobile Services (HMS)');
  print('  2. Настроить Google Firebase Services');
  print('  3. Настроить оба провайдера (Huawei + Google)');
  print('  4. Только очистить настройки провайдеров');
  print('  0. Отмена (ничего не делать)');
  print('');
  stdout.write('Введите номер (0-4): ');

  final choice = stdin.readLineSync()?.trim();

  print('');

  try {
    switch (choice) {
      case '1':
        print('🔧 Настройка Huawei HMS...');
        print('');
        huawei.setupHuaweiForProject(projectPath);
        print('');
        print('✅ Настройка Huawei завершена успешно!');
        print('');
        print('📝 Следующие шаги:');
        print(
          '   • Добавьте файл agconnect-services.json в папку android/app/',
        );
        print('   • Выполните: flutter pub get');
        print('');
        print('🎉 Все настройки flutter_unisdk выполнены успешно.');
        break;

      case '2':
        print('🔧 Настройка Google Firebase...');
        print('');
        google.setupGoogleForProject(projectPath);
        print('');
        print('✅ Настройка Google завершена успешно!');
        print('');
        print('📝 Следующие шаги:');
        print('   • Добавьте файл google-services.json в папку android/app/');
        print(
          '   • Убедитесь, что иконка уведомлений firebase_icon_push лежит в android/app/src/main/res/drawable/',
        );
        print('   • Выполните: flutter pub get');
        print('');
        print('🎉 Все настройки flutter_unisdk выполнены успешно.');
        break;

      case '3':
        print('🔧 Настройка обоих провайдеров...');
        print('');
        print('--- Настройка Huawei ---');
        huawei.setupHuaweiForProject(projectPath);
        print('');
        print('--- Настройка Google ---');
        google.setupGoogleForProject(projectPath);
        print('');

        // Для сценария "оба провайдера" дополнительно добавляем
        // huawei_hmsavailability в pubspec.yaml
        _setupBothProvidersPubspec(projectPath);

        print('✅ Настройка обоих провайдеров завершена успешно!');
        print('');
        print('📝 Следующие шаги:');
        print(
          '   • Добавьте файл agconnect-services.json в папку android/app/',
        );
        print('   • Добавьте файл google-services.json в папку android/app/');
        print(
          '   • Убедитесь, что иконка уведомлений firebase_icon_push лежит в android/app/src/main/res/drawable/',
        );
        print('   • Выполните: flutter pub get');
        print('');
        print('🎉 Все настройки flutter_unisdk выполнены успешно.');
        break;

      case '4':
        print('🧹 Очистка настроек провайдеров...');
        print('');
        cleanAndroidProject(androidPath);
        cleanPubspec(projectPath);
        print('');
        print('✅ Очистка завершена. Никакие провайдеры не были настроены.');
        break;

      case '0':
        print('ℹ️ Операция отменена пользователем. Ничего не изменено.');
        break;

      default:
        print('❌ Неверный выбор. Ничего не делаю.');
    }
    // Явно завершаем процесс после успешной настройки,
    // чтобы не было ощущения "зависшего" скрипта.
    exit(0);
  } catch (e, stackTrace) {
    print('❌ Ошибка при настройке: $e');
    print(stackTrace);
    exit(1);
  }
}

/// Дополнительная настройка pubspec.yaml для сценария "оба провайдера":
/// добавляем только huawei_hmsavailability (остальные Huawei-зависимости
/// добавляются в setupHuaweiPubspec для чистого Huawei-режима).
void _setupBothProvidersPubspec(String projectPath) {
  final pubspecFile = File('$projectPath/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print(
      '⚠️  Предупреждение: pubspec.yaml не найден, пропускаю добавление huawei_hmsavailability',
    );
    return;
  }

  final lines = pubspecFile.readAsLinesSync();

  // Проверяем, есть ли уже зависимость
  final hasAvailability = lines.any(
    (l) => l.trimLeft().startsWith('huawei_hmsavailability:'),
  );
  if (hasAvailability) {
    print(
      'ℹ️  Зависимость huawei_hmsavailability уже присутствует в pubspec.yaml',
    );
    return;
  }

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
        '⚠️  Не удалось найти секцию environment в pubspec.yaml, пропускаю добавление huawei_hmsavailability',
      );
      return;
    }
  }

  // Идём вниз от строки `dependencies:` пока строки начинаются с двух пробелов
  int insertIndex = depsIndex + 1;
  while (insertIndex < lines.length) {
    final line = lines[insertIndex];
    if (line.startsWith('  ') && line.trim().isNotEmpty) {
      insertIndex++;
      continue;
    }
    break;
  }

  const block = [
    '  huawei_hmsavailability:',
    '    git:',
    '      url: https://github.com/norutplz/hms-flutter-plugin.git',
    '      ref: hms_push_flutter_3.29',
    '      path: flutter-hms-availability',
    '',
  ];

  lines.insertAll(insertIndex, block);
  changed = true;
  print(
    '✅ Добавлена зависимость huawei_hmsavailability в pubspec.yaml (оба провайдера)',
  );

  if (changed) {
    pubspecFile.writeAsStringSync(lines.join('\n'));
  }
}
