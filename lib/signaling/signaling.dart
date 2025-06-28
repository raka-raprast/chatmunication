import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Signaling {
  final String serverUrl;
  final String roomId;
  final String token;

  late WebSocketChannel _channel;
  late RTCPeerConnection _peerConnection;
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();
  final localStreamReady = ValueNotifier<bool>(false);
  final remoteStreamReady = ValueNotifier<bool>(false);
  final VoidCallback? onPeerDisconnected;
  late MediaStream _localStream;
  late MediaStream _remoteStream;
  MediaStream get localStream => _localStream;
  MediaStream get remoteStream => _remoteStream;

  bool _isReady = false;
  bool _otherReady = false;
  late bool isCaller;
  final String callType;

  Signaling({
    required this.serverUrl,
    required this.roomId,
    required this.token,
    required this.callType,
    this.onPeerDisconnected,
  });

  Future<void> initRenderers() async {
    if (callType == 'video') {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    }
  }

  Future<void> connect() async {
    final uri = Uri.parse('$serverUrl/ws?token=$token&room=$roomId');
    _channel = WebSocketChannel.connect(uri);

    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      _handleSignaling(data);
    });

    await _createPeerConnection();

    _send({'type': 'ready'});
    _isReady = true;

    if (isCaller && _otherReady) {
      print("📞 Caller: both ready, making offer...");
      await makeOffer();
    }
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
        if (callType == 'video') {
          remoteRenderer.srcObject = event.streams[0];
        }
        remoteStreamReady.value = true;
      }
    };

    _peerConnection.onConnectionState = (state) {
      print("🟡 Connection state: $state");

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        print("🔴 Peer disconnected. Calling onPeerDisconnected...");
        resetRemoteRenderer();
        onPeerDisconnected?.call();
      }
    };

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': callType == 'video',
    });

    print(
        "🎥 Got local stream. Video tracks: ${stream.getVideoTracks().length}");
    if (callType == 'video') {
      localRenderer.srcObject = stream;
    }
    _localStream = stream;
    localStreamReady.value = true;

    for (var track in stream.getTracks()) {
      _peerConnection.addTrack(track, stream);
    }
  }

  void resetRemoteRenderer() {
    _otherReady = false;
    remoteRenderer.srcObject = null;
    remoteStreamReady.value = false;
  }

  void _handleSignaling(Map<String, dynamic> data) async {
    switch (data['type']) {
      case 'join_ack':
        final userCount = data['userCount'] as int;
        isCaller = userCount == 1;
        print("📲 Role decided: ${isCaller ? 'Caller' : 'Callee'}");

        _send({'type': 'ready'});
        _isReady = true;
        if (isCaller && _otherReady) {
          await makeOffer();
        }
        break;

      case 'ready':
        _otherReady = true;
        print("✅ Peer is ready");
        if (isCaller && _isReady) {
          await makeOffer();
        }
        break;

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
      case 'user_left':
        print("👋 Peer has left the call");
        if (callType == 'video') {
          resetRemoteRenderer();
        }
        onPeerDisconnected?.call();
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
    _send({'type': 'leave'});
    _peerConnection.close();
    _channel.sink.close();
    localRenderer.dispose();
    remoteRenderer.dispose();
  }
}
