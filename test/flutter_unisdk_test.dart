import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unisdk/flutter_unisdk.dart';
import 'package:flutter_unisdk/flutter_unisdk_platform_interface.dart';
import 'package:flutter_unisdk/flutter_unisdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterUnisdkPlatform
    with MockPlatformInterfaceMixin
    implements FlutterUnisdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterUnisdkPlatform initialPlatform = FlutterUnisdkPlatform.instance;

  test('$MethodChannelFlutterUnisdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterUnisdk>());
  });

  test('getPlatformVersion', () async {
    FlutterUnisdk flutterUnisdkPlugin = FlutterUnisdk();
    MockFlutterUnisdkPlatform fakePlatform = MockFlutterUnisdkPlatform();
    FlutterUnisdkPlatform.instance = fakePlatform;

    expect(await flutterUnisdkPlugin.getPlatformVersion(), '42');
  });
}
