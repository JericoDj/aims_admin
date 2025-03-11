// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../services/webrtc_service.dart';
import 'components/call_page_widget.dart';

class CallPage extends StatefulWidget {
  String? roomId;
  bool isCaller;

  /// if 'roomId' = null; new call will be made.
  /// if 'roomId' != null; will join the room.
  CallPage({
    Key? key,
    required this.roomId,
    required this.isCaller,
  }) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late FirebaseFirestore videoapp;
  late WebRtcService fbCallService;

  RTCPeerConnection? peerConnection;
  final localVideo = RTCVideoRenderer();
  MediaStream? localStream;

  final remoteVideo = RTCVideoRenderer();

  bool connectingLoading = true;

  // media status
  bool isAudioOn = true;
  bool isVideoOn = true;
  bool isFrontCameraSelected = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () async {
      fbCallService = Provider.of<WebRtcService>(context, listen: false);
      await openCamera();
      init();
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = "";

    if (widget.roomId != null) {
      title = "Room ID: ${widget.roomId}";
    } else {
      title = "Loading... Wait...";
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade800,
        leading: const SizedBox(),
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
      body: CallPageWidget(
        connectingLoading: connectingLoading,
        roomId: widget.roomId ?? "",
        remoteVideo: remoteVideo,
        localVideo: localVideo,
        leaveCall: () => _leaveCall(),
        switchCamera: () => _switchCamera(),
        toggleCamera: () => _toggleCamera(),
        toggleMic: () => _toggleMic(),
        isAudioOn: isAudioOn,
        isVideoOn: isVideoOn,
        isCaller: widget.isCaller,
      ),
    );
  }

  Future<void> init() async {
    try {
      await remoteVideo.initialize();
      final remoteStreams = peerConnection?.getRemoteStreams();

      if (remoteStreams != null && remoteStreams.isEmpty) {
        peerConnection?.onTrack = (event) {
          if (event.track.kind == 'video') {
            setState(() {
              remoteVideo.srcObject = event.streams.first;
            });
          }
        };
      }

      if (widget.roomId == null) {
        String newRoomId = await fbCallService.call();
        setState(() {
          widget.roomId = newRoomId;
        });
        iceStatusListen();
      } else {
        await fbCallService.answer(roomId: widget.roomId.toString());
        iceStatusListen();
      }
    } catch (e) {
      debugPrint("************** call_start_page : LN=77 : $e");
    }
  }

  Future<void> openCamera() async {
    await localVideo.initialize();
    peerConnection = await fbCallService.createPeer();

    final Map<String, dynamic> mediaConstraints = {
      'audio': isAudioOn,
      'video': isVideoOn,
    };

    localStream = await navigator.mediaDevices.getUserMedia(
      mediaConstraints,
    );

    localStream!.getTracks().forEach(
          (track) async => await peerConnection?.addTrack(
            track,
            localStream!,
          ),
        );
    localVideo.srcObject = localStream;
    setState(() {});
  }

  void iceStatusListen() {
    try {
      peerConnection!.onIceConnectionState = (iceConnectionState) async {
        if ((peerConnection!.iceConnectionState ==
                RTCIceConnectionState.RTCIceConnectionStateConnected ||
            peerConnection!.iceConnectionState ==
                RTCIceConnectionState.RTCIceConnectionStateCompleted)) {
          _connectingLoadingComplated();
        }

        if (iceConnectionState ==
                RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
            iceConnectionState ==
                RTCIceConnectionState.RTCIceConnectionStateFailed) {
          // The other person left the chat or was disconnected.
          _leaveCall();
        }
      };
    } catch (e) {
      debugPrint("********* call_start_page : LN=109 : $e");
    }
  }

  void _connectingLoadingComplated() {
    if (mounted && connectingLoading) {
      setState(() {
        connectingLoading = false;
      });
    }
  }

  /// The other person left the chat or was disconnected.
  void _leaveCall() {
    if (mounted) {
      Navigator.pop(context);
      fbCallService.deleteFirebaseDoc(
        roomId: widget.roomId.toString(),
      );
    }
  }

  _toggleMic() {
    isAudioOn = !isAudioOn;
    // enable or disable audio track
    localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }

  _toggleCamera() {
    isVideoOn = !isVideoOn;
    // enable or disable video track
    localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  _switchCamera() {
    isFrontCameraSelected = !isFrontCameraSelected;
    localStream?.getVideoTracks().forEach((track) {
      // ignore: deprecated_member_use
      track.switchCamera();
    });
    setState(() {});
  }

  @override
  void dispose() async {
    peerConnection?.close();
    localStream?.getTracks().forEach((track) {
      track.stop();
    });
    localVideo.dispose();
    remoteVideo.dispose();
    localStream?.dispose();
    peerConnection?.dispose();
    super.dispose();
  }
}
