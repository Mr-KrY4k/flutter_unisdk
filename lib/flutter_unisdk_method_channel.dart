import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_unisdk_platform_interface.dart';

/// An implementation of [FlutterUnisdkPlatform] that uses method channels.
class MethodChannelFlutterUnisdk extends FlutterUnisdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_unisdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
