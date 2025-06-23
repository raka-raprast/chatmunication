import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';

class Signaling {
  final String serverUrl;
  final String roomId;
  final String token;

  late WebSocketChannel _channel;
  late RTCPeerConnection _peerConnection;
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  Signaling({
    required this.serverUrl,
    required this.roomId,
    required this.token,
  });

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  bool hasMadeOffer = false;

  Future<void> connect() async {
    // 💡 Set this first to avoid uninitialized access
    final uri = Uri.parse('$serverUrl/ws?token=$token&room=$roomId');
    _channel = WebSocketChannel.connect(uri);

    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      _handleSignaling(data);
    });

    await _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection.onIceCandidate = (candidate) {
      if (candidate != null) {
        _send({
          'type': 'candidate',
          'candidate': candidate.toMap(),
        });
      }
    };

    _peerConnection.onTrack = (event) {
      print("🟢 Received track: ${event.track.kind}");
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    _peerConnection.onConnectionState = (state) {
      print("🟡 Connection state: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        // Maybe retry or alert user
        print("🔴 PeerConnection closed or failed");
      }
    };

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    print(
        "🎥 Got local stream. Video tracks: ${stream.getVideoTracks().length}");

    localRenderer.srcObject = stream;

    for (var track in stream.getTracks()) {
      _peerConnection.addTrack(track, stream);
    }
  }

  void _handleSignaling(Map<String, dynamic> data) async {
    print(
        "📩 Received ${data['type']}: ${data['sdp']?.toString().contains("m=video") == true ? "includes video" : "NO VIDEO"}");
    switch (data['type']) {
      case 'offer':
        await _peerConnection
            .setRemoteDescription(RTCSessionDescription(data['sdp'], 'offer'));
        final answer = await _peerConnection.createAnswer();
        await _peerConnection.setLocalDescription(answer);
        _send({'type': 'answer', 'sdp': answer.sdp});
        break;

      case 'answer':
        await _peerConnection
            .setRemoteDescription(RTCSessionDescription(data['sdp'], 'answer'));
        break;

      case 'candidate':
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        await _peerConnection.addCandidate(candidate);
        break;
    }
  }

  Future<void> makeOffer() async {
    final offer = await _peerConnection.createOffer();
    print(
        "📨 Sending offer: ${offer.sdp?.contains("m=video") == true ? "includes video" : "NO VIDEO"}");

    await _peerConnection.setLocalDescription(offer);
    _send({'type': 'offer', 'sdp': offer.sdp});
  }

  void _send(Map<String, dynamic> data) {
    _channel.sink.add(jsonEncode(data));
  }

  void dispose() {
    _peerConnection.close();
    _channel.sink.close();
    localRenderer.dispose();
    remoteRenderer.dispose();
  }
}
