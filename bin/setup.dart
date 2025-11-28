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
  print('  3. Только очистить настройки провайдеров');
  print('  0. Отмена (ничего не делать)');
  print('');
  stdout.write('Введите номер (0-3): ');

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
