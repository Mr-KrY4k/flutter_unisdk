# flutter_unisdk

Flutter плагин для интеграции Huawei Mobile Services (HMS). Плагин автоматически настраивает все необходимые компоненты Huawei SDK, включая Push Kit, Analytics, Ads Identifier и другие сервисы.

## Особенности

- ✅ Автоматическая настройка всех Huawei компонентов
- ✅ Встроенные зависимости HMS SDK
- ✅ Автоматическое добавление ProGuard правил
- ✅ Настройка манифеста (receivers, queries)
- ✅ Минимальная настройка в проекте

## Установка

### 1. Добавьте плагин в `pubspec.yaml`

```yaml
dependencies:
  flutter_unisdk:
    path: ../flutter_unisdk  # или git/версия
```

Затем выполните:
```bash
flutter pub get
```

### 2. Автоматическая настройка Gradle

Запустите скрипт установки (один раз):

```bash
dart tool/setup_huawei.dart /path/to/your/flutter/project
```

Скрипт автоматически:
- Добавит Huawei репозиторий в `android/settings.gradle.kts`
- Настроит плагин `com.huawei.agconnect`
- Добавит необходимые конфигурации в `android/app/build.gradle.kts`

**Пример:**
```bash
dart tool/setup_huawei.dart /Users/username/my_flutter_app
```

### 3. Добавьте конфигурационный файл

Скопируйте файл `agconnect-services.json` в папку `android/app/` вашего проекта.

Этот файл можно получить в [Huawei AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html).

### 4. Готово! 🎉

Больше ничего настраивать не нужно. Плагин автоматически:
- Подключит все необходимые HMS зависимости
- Настроит манифест (receivers, queries)
- Применит ProGuard правила
- Инициализирует Huawei сервисы

## Что включает плагин

### Зависимости HMS SDK

- `com.huawei.hms:push:6.12.0.300` - Push Kit
- `com.huawei.hms:hianalytics:6.12.0.300` - Analytics
- `com.huawei.hms:hwid:6.12.0.300` - Account Kit
- `com.huawei.hms:base:6.12.0.300` - Base SDK
- `com.huawei.hms:ads-identifier:3.4.68.300` - Ads Identifier

### AndroidManifest.xml

Плагин автоматически добавляет:
- Receivers для Push Kit (BootEventReceiver, ScheduledPublisher, BackgroundMessageBroadcastReceiver)
- Queries для HMS Core AIDL service
- Meta-data для автоматической инициализации Push Kit

### ProGuard правила

Все необходимые правила для Huawei SDK включены в `consumer-rules.pro` и применяются автоматически.

## Использование

```dart
import 'package:flutter_unisdk/flutter_unisdk.dart';

// Плагин автоматически инициализируется при запуске приложения
// Все Huawei сервисы доступны через нативные вызовы
```

## Требования

- Flutter >= 3.3.0
- Android minSdk: 24
- Android compileSdk: 36
- Kotlin: 2.2.20+
- Java: 17+

## Поддержка

Если у вас возникли проблемы:
1. Убедитесь, что скрипт установки выполнен успешно
2. Проверьте наличие `agconnect-services.json` в `android/app/`
3. Убедитесь, что в `android/settings.gradle.kts` есть Huawei репозиторий
4. Проверьте, что плагин `com.huawei.agconnect` добавлен в `android/app/build.gradle.kts`

## Лицензия

См. файл [LICENSE](LICENSE).
