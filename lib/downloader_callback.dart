import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';

class DownloaderCallback {
  static void callbackDownloader(String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_port')!;
    send.send([id, status, progress]);
  }
}