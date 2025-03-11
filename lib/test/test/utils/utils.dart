class Utils {
  static List<Map<String, String>> getIceServers() {
    //! Change the TURN information in the lib/utils/utils.dart file
    //! Some services that provide free TURN include;
    //! - https://www.metered.ca/stun-turn

    return [
      {"url": "stun:stun.l.google.com:19302"},
      {
        "url": "turn:eu-0.turn.peerjs.com:3478",
        "username": "peerjs",
        "credential": "peerjsp",
      },
    ];
  }
}
