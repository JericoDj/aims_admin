import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// ignore: must_be_immutable
class CallPageWidget extends StatelessWidget {
  bool connectingLoading;
  String roomId;
  bool isCaller;
  RTCVideoRenderer remoteVideo;
  RTCVideoRenderer localVideo;
  VoidCallback leaveCall;
  VoidCallback switchCamera;
  VoidCallback toggleCamera;
  VoidCallback toggleMic;
  bool isAudioOn;
  bool isVideoOn;


  CallPageWidget({
    super.key,
    required this.connectingLoading,
    required this.roomId,
    required this.isCaller,
    required this.remoteVideo,
    required this.localVideo,
    required this.leaveCall,
    required this.switchCamera,
    required this.toggleCamera,
    required this.toggleMic,
    required this.isAudioOn,
    required this.isVideoOn,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Stack(
        alignment: AlignmentDirectional.bottomEnd,
        children: [
          if (connectingLoading == false)
            SizedBox(
              height: size.height,
              width: size.width,
              child: RTCVideoView(
                remoteVideo,
                mirror: true,
              ),
            )
          else if (isCaller)
            Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 10,
              ),
              height: size.height,
              width: size.width,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Waiting for participant...",
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Share your room ID.",
                      style: TextStyle(
                        fontSize: 17.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      alignment: Alignment.center,
                      color: Colors.grey,
                      height: 48,
                      width: size.width - 30,
                      child: Text(
                        roomId,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17.4,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: SizedBox(
              height: size.height / 4.76,
              width: size.width / 4,
              child: RTCVideoView(
                localVideo,
                mirror: true,
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 10,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => leaveCall(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(
                        Radius.circular(1000),
                      ),
                    ),
                    child: const Icon(
                      Icons.call_end,
                      size: 27,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    try {
                      switchCamera();
                    } catch (e) {
                      //
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(1000),
                      ),
                    ),
                    child: const Icon(
                      Icons.switch_camera,
                      size: 23,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    try {
                      toggleCamera();
                    } catch (e) {
                      //
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isVideoOn ? Colors.grey.shade700 : Colors.white,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(1000),
                      ),
                    ),
                    child: Icon(
                      isVideoOn ? Icons.videocam : Icons.videocam_off,
                      size: 23,
                      color: isVideoOn ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    try {
                      toggleMic();
                    } catch (e) {
                      //
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAudioOn ? Colors.grey.shade700 : Colors.white,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(1000),
                      ),
                    ),
                    child: Icon(
                      isAudioOn ? Icons.mic : Icons.mic_off,
                      size: 23,
                      color: isAudioOn ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
