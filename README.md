# flutter_unisdk

Универсальный Flutter плагин для интеграции мобильных сервисов. Поддерживает **Huawei Mobile Services (HMS)** и **Google Firebase Services**. Плагин автоматически настраивает все необходимые компоненты в зависимости от выбранного провайдера.

## Особенности

- ✅ **Универсальность**: Поддержка Huawei HMS и Google Firebase
- ✅ **Автоматическая настройка**: Все компоненты настраиваются автоматически
- ✅ **Условные зависимости**: Подключаются только нужные зависимости
- ✅ **Гибкость**: Можно использовать один провайдер или оба одновременно
- ✅ **Минимальная настройка**: Только JSON конфиг и одна команда

## Быстрый старт

1. **Добавьте плагин в `pubspec.yaml`:**
   ```yaml
   dependencies:
     flutter_unisdk:
       git:
         url: https://github.com/your-username/flutter_unisdk.git
         ref: main
   ```

2. **Установите зависимости:**
   ```bash
   flutter pub get
   ```

3. **Настройте проект:**
   ```bash
   # Запустите из корня вашего проекта
   dart run flutter_unisdk:setup
   ```

4. **Добавьте конфигурационные файлы:**
   - Для Huawei: `agconnect-services.json` → `android/app/`
   - Для Google: `google-services.json` → `android/app/`

Готово! 🎉

## Поддерживаемые провайдеры

### Huawei Mobile Services (HMS)
- Push Kit
- Analytics (HiAnalytics)
- Account Kit (HWID)
- Ads Identifier
- Base SDK

### Google Firebase Services
- Firebase Cloud Messaging (FCM)
- Firebase Analytics
- Firebase Crashlytics
- Firebase Remote Config
- Google Play Services Ads Identifier

## Установка

### 1. Добавьте плагин в `pubspec.yaml`

#### Вариант 1: Из GitHub (рекомендуется)

```yaml
dependencies:
  flutter_unisdk:
    git:
      url: https://github.com/your-username/flutter_unisdk.git
      ref: main  # или конкретный тег/ветка, например: v0.0.1
```

**Примеры:**
```yaml
# Использование конкретной ветки
dependencies:
  flutter_unisdk:
    git:
      url: https://github.com/your-username/flutter_unisdk.git
      ref: main

# Использование конкретного тега/версии
dependencies:
  flutter_unisdk:
    git:
      url: https://github.com/your-username/flutter_unisdk.git
      ref: v0.0.1

# Использование конкретного коммита
dependencies:
  flutter_unisdk:
    git:
      url: https://github.com/your-username/flutter_unisdk.git
      ref: abc123def456
```

#### Вариант 2: Локально (для разработки)

```yaml
dependencies:
  flutter_unisdk:
    path: ../flutter_unisdk
```

Затем выполните:
```bash
flutter pub get
```

> **Важно:** 
> - Замените `your-username` на ваш GitHub username
> - Замените `main` на нужную ветку/тег/коммит
> - Для стабильной версии рекомендуется использовать теги (например, `v0.0.1`)

### 2. Настройте проект

**Запустите из корня вашего проекта:**

```bash
dart run flutter_unisdk:setup
```

Скрипт автоматически:
- Использует текущую директорию как путь к проекту
- Предложит выбрать провайдер (1 - Huawei, 2 - Google, 3 - Оба)
- Настроит всё автоматически

**Интерактивный режим:**

Скрипт предложит выбрать провайдер:
1. **Huawei Mobile Services (HMS)** - только Huawei
2. **Google Firebase Services** - только Google
3. **Оба провайдера** - Huawei + Google одновременно

**Что делает скрипт:**

Скрипт автоматически:
- Установит провайдер в `android/gradle.properties` плагина
- Добавит необходимые репозитории в `android/settings.gradle.kts`
- Настроит плагины в `android/app/build.gradle.kts`
- Добавит зависимости в `pubspec.yaml`

### 3. Добавьте конфигурационные файлы

#### Для Huawei:
Скопируйте файл `agconnect-services.json` в папку `android/app/` вашего проекта.

Этот файл можно получить в [Huawei AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html).

#### Для Google:
Скопируйте файл `google-services.json` в папку `android/app/` вашего проекта.

Этот файл можно получить в [Firebase Console](https://console.firebase.google.com/).

> **Примечание:** Для использования обоих провайдеров выберите опцию "3. Оба провайдера" при запуске скрипта, затем добавьте оба файла: `agconnect-services.json` и `google-services.json`.

### 4. Готово! 🎉

Больше ничего настраивать не нужно. Плагин автоматически:
- Подключит только нужные зависимости для выбранного провайдера
- Настроит манифест (receivers, queries)
- Применит ProGuard правила
- Инициализирует сервисы

## Что включает плагин

### Зависимости (подключаются условно)

#### Huawei HMS SDK
- `com.huawei.hms:push:6.12.0.300` - Push Kit
- `com.huawei.hms:hianalytics:6.12.0.300` - Analytics
- `com.huawei.hms:hwid:6.12.0.300` - Account Kit
- `com.huawei.hms:base:6.12.0.300` - Base SDK
- `com.huawei.hms:ads-identifier:3.4.68.300` - Ads Identifier

#### Google Firebase SDK
- `com.google.firebase:firebase-bom:33.7.0` - Firebase BOM
- `com.google.firebase:firebase-messaging` - Cloud Messaging
- `com.google.firebase:firebase-analytics` - Analytics
- `com.google.firebase:firebase-crashlytics` - Crashlytics
- `com.google.firebase:firebase-config` - Remote Config
- `com.google.android.gms:play-services-ads-identifier:18.1.0` - Ads Identifier

### AndroidManifest.xml

Плагин автоматически добавляет компоненты в зависимости от провайдера:

**Huawei:**
- Receivers для Push Kit
- Queries для HMS Core AIDL service
- Meta-data для автоматической инициализации

**Google:**
- Meta-data для Firebase notification icon
- Остальные настройки через `google-services.json`

**Both:**
- Комбинация компонентов обоих провайдеров

### ProGuard правила

ProGuard правила применяются только для Huawei:
- `consumer-rules-huawei.pro` - для Huawei (применяется автоматически)
- Google Firebase не требует специальных ProGuard правил в плагине

## Использование

```dart
import 'package:flutter_unisdk/flutter_unisdk.dart';

// Плагин автоматически инициализируется при запуске приложения
// Все сервисы доступны через нативные вызовы в зависимости от провайдера

final flutterUnisdk = FlutterUnisdk();
final platformVersion = await flutterUnisdk.getPlatformVersion();
```

## Пример

В папке `example/` находится пример использования плагина. Для запуска примера:

```bash
cd example
flutter pub get
flutter run
```

> **Примечание:** Пример использует `path: ../` зависимость, что нормально для примера внутри репозитория плагина. В вашем проекте используйте `git` зависимость как описано выше.

## Настройка провайдера

Провайдер настраивается автоматически при запуске соответствующего скрипта и сохраняется в `android/gradle.properties` плагина:

```properties
# Провайдер сервисов: huawei, google, both
unisdk.provider=google
```

Для изменения провайдера просто запустите скрипт снова и выберите нужный провайдер:
```bash
dart run flutter_unisdk:setup
```

## Требования

- Flutter >= 3.3.0
- Android minSdk: 24
- Android compileSdk: 36
- Kotlin: 2.2.20+
- Java: 17+

## Поддержка

Если у вас возникли проблемы:

1. **Проверьте провайдер:**
   - Убедитесь, что в `android/gradle.properties` плагина установлен правильный провайдер
   - Перезапустите скрипт `dart run flutter_unisdk:setup` если нужно изменить провайдер

2. **Проверьте конфигурационные файлы:**
   - Для Huawei: `agconnect-services.json` в `android/app/`
   - Для Google: `google-services.json` в `android/app/`

3. **Проверьте Gradle настройки:**
   - Убедитесь, что скрипт установки выполнен успешно
   - Проверьте наличие репозиториев в `android/settings.gradle.kts`
   - Проверьте наличие плагинов в `android/app/build.gradle.kts`

4. **Очистите и пересоберите:**
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean && cd ..
   flutter build apk
   ```

## Миграция между провайдерами

Чтобы изменить провайдер:

1. Запустите скрипт установки и выберите нужный провайдер:
   ```bash
   dart run flutter_unisdk:setup
   ```

2. Обновите конфигурационные файлы (если нужно)

3. Очистите и пересоберите проект

## Лицензия

См. файл [LICENSE](LICENSE).
