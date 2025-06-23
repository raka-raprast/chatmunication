import 'dart:io';

import 'package:chatmunication/signaling/signaling.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  final String token;
  final String roomId;
  final bool isCaller;

  const CallScreen(
      {required this.token, required this.roomId, required this.isCaller});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late Signaling signaling;

  @override
  void initState() {
    super.initState();

    signaling = Signaling(
      serverUrl: 'ws://192.168.100.113:2340',
      roomId: widget.roomId,
      token: widget.token,
    );
    _start();
  }

  Future<void> ensurePermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      throw Exception('Camera and microphone permissions are required');
    }
  }

  Future<bool> isRunningOnEmulator() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final model = androidInfo.model?.toLowerCase() ?? '';
      final manufacturer = androidInfo.manufacturer?.toLowerCase() ?? '';
      final brand = androidInfo.brand?.toLowerCase() ?? '';

      return model.contains('sdk') ||
          model.contains('emulator') ||
          manufacturer.contains('genymotion') ||
          brand.contains('generic');
    }

    if (Platform.isIOS) {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      return iosInfo.isPhysicalDevice == false;
    }

    return false;
  }

  Future<void> _start() async {
    await ensurePermissions();
    await signaling.initRenderers();
    await signaling.connect();

    final emulator = await isRunningOnEmulator();
    if (widget.isCaller) {
      print("📱 Caller → Making offer");
      await signaling.makeOffer();
    } else {
      print("📱 Callee → Waiting for offer");
    }
  }

  @override
  void dispose() {
    signaling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Call')),
      body: Row(
        children: [
          Expanded(child: RTCVideoView(signaling.localRenderer)),
          Expanded(child: RTCVideoView(signaling.remoteRenderer)),
        ],
      ),
    );
  }
}
