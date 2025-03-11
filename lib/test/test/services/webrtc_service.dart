import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../utils/utils.dart';

Map<String, dynamic> configuration = {
  "iceServers": Utils.getIceServers(),
};

Map<String, dynamic> offerSdpConstraints = {
  "mandatory": {
    "OfferToReceiveAudio": true,
    "OfferToReceiveVideo": true,
  },
  "optional": [
    {'DtlsSrtpKeyAgreement': true},
  ],
};

class WebRtcService extends ChangeNotifier {
  late RTCPeerConnection peerConnection;
  late FirebaseFirestore videoapp;

  WebRtcService() {
    videoapp = FirebaseFirestore.instance;
  }

  Future<RTCPeerConnection> createPeer() async {
    peerConnection = await createPeerConnection(
      configuration,
      offerSdpConstraints,
    );
    return peerConnection;
  }

  /// Generates random room id.
  String _createRoomId() {
    Random random = Random();
    int randomNumber = random.nextInt(9000) + 1000;
    return randomNumber.toString();
  }

  /// The room id is created and the search is started. The room id is returned.
  Future<String> call() async {
    try {
      String newRoomId = _createRoomId();
      final callDoc = videoapp.collection('calls').doc(newRoomId);
      final offerCandidates = callDoc.collection('offerCandidates');
      final answerCandidates = callDoc.collection('answerCandidates');

      peerConnection.onIceCandidate = (event) {
        if (event.candidate != null) offerCandidates.add(event.toMap());
      };

      callDoc.snapshots().listen(
        (snapshot) async {
          final data = snapshot.data();
          if (data != null &&
              (await peerConnection.getRemoteDescription() == null) &&
              data.containsKey('answer')) {
            final answerDescription = RTCSessionDescription(
                data['answer']['sdp'], data['answer']['type']);
            peerConnection.setRemoteDescription(answerDescription);
          }
        },
      );

      answerCandidates.snapshots().listen(
        (snapshot) async {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              final candidate = RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              );
              peerConnection.addCandidate(candidate);
            }
          }
        },
      );

      final description = await peerConnection.createOffer();
      final offer = {
        'offer': {'sdp': description.sdp, 'type': description.type}
      };

      await peerConnection.setLocalDescription(description);
      await callDoc.set(offer);

      return callDoc.id;
    } catch (e) {
      debugPrint("************ webrtc_service : call : $e");
      return "";
    }
  }

  /// Join the room.
  Future<void> answer({
    required String roomId,
  }) async {
    try {
      final callDoc = videoapp.collection('calls').doc(roomId);
      final answerCandidates = callDoc.collection('answerCandidates');
      final offerCandidates = callDoc.collection('offerCandidates');

      peerConnection.onIceCandidate = (event) {
        if (event.candidate != null) answerCandidates.add(event.toMap());
      };

      final callData = (await callDoc.get()).data();

      final offerDescription = callData!['offer'];
      await peerConnection.setRemoteDescription(
        RTCSessionDescription(
          offerDescription['sdp'],
          offerDescription['type'],
        ),
      );

      final description = await peerConnection.createAnswer();
      final answer = {
        'answer': {'sdp': description.sdp, 'type': description.type}
      };

      offerCandidates.snapshots().listen(
        (snapshot) async {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              final candidate = RTCIceCandidate(
                  data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
              peerConnection.addCandidate(candidate);
            }
          }
        },
      );

      await peerConnection.setLocalDescription(description);
      await callDoc.update(answer);
    } catch (e) {
      debugPrint("********** webrtc_service : answer : $e");
    }
  }

  Future<void> deleteFirebaseDoc({required String roomId}) async {
    try {
      final callDoc = videoapp.collection('calls').doc(roomId);
      await callDoc.delete();
    } catch (e) {
      //
    }
  }
}
