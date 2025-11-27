import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_unisdk_method_channel.dart';

abstract class FlutterUnisdkPlatform extends PlatformInterface {
  /// Constructs a FlutterUnisdkPlatform.
  FlutterUnisdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterUnisdkPlatform _instance = MethodChannelFlutterUnisdk();

  /// The default instance of [FlutterUnisdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterUnisdk].
  static FlutterUnisdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterUnisdkPlatform] when
  /// they register themselves.
  static set instance(FlutterUnisdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
