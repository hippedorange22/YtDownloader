import 'package:flutter/services.dart';

class ShareService {
  void Function(String)? onDataReceived;

  ShareService() {
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg?.contains("resumed") ?? false) {
        getSharedData().then((String data) {
          if (data.isEmpty) {
            return;
          }


          onDataReceived?.call(data);
        });
      }
      return;
    });
  }

  Future<String> getSharedData() async {
    return await MethodChannel('com.hippedorange22.youtubedownloader')
        .invokeMethod("getSharedData") ??
        "";
  }
}