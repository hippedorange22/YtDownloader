import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path/path.dart' as pathh;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class TestHome extends StatefulWidget {
  const TestHome({Key? key}) : super(key: key);

  @override
  _TestHomeState createState() => _TestHomeState();
}

class _TestHomeState extends State<TestHome> {
  YoutubeExplode ytDl = YoutubeExplode();
  String searchQuery = "";
  String vidTitle = "";
  String downloadsPath = "storage/emulated/0/YTDownloads";

  List<String> vidTitles = [];
  List vidQuality = [];
  bool isLoading = false;
  Color baseColor = Color(0xFFf2f2f2);
  late VideoQuality cVideoQuality;
  final progressListenable = ValueNotifier<int>(0);
  String progress = "";
  bool downloading = false;

  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return ValueListenableBuilder(
      valueListenable: progressListenable,
      builder: (context, i, child) => SafeArea(
          child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 0.02 * screenSize.height),
            isLoading ? Container(

                child:
                Container(
                    width: 0.85 * screenSize.width,
                    child: NeumorphicProgressIndeterminate())) : Container(),
            SizedBox(height: 0.01 * screenSize.height),
            Center(
              child: Container(
                width: 0.9 * screenSize.width,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 20,
                  child: TextField(
                    decoration: InputDecoration(border: InputBorder.none),
                    onChanged: (val) {
                      searchQuery = val;
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 0.02 * screenSize.height),
            NeumorphicButton(
              style: NeumorphicStyle(
                color: baseColor,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
              ),
              child: Text("Search"),
              onPressed: () async {
                try {} on Exception catch (_) {
                  print(_.toString());
                }
                setState(() {
                  isLoading = true;
                });
                await ytDl.search.getVideos(searchQuery).then((value) async {
                  for (int index = 0; index < 5; index++) {
                    vidTitles.add(value[index].id.toString());
                  }

                  return;
                });
                var id = VideoId(vidTitles[0].trim());
                var manifest = await ytDl.videos.streamsClient.getManifest(id);
                var vid = manifest.video.where((element) => element.videoQualityLabel == "1080p");
                var vidP = ytDl.videos.streamsClient.get(vid.first);
                print("Title: ${vid.first.videoQualityLabel}");
                var filePath = pathh.join(downloadsPath, "testVid.mp4");
                var len = vid.first.size.totalBytes;
                var count = 0;
                var file = File(filePath);
                var vidStream = file.openWrite();
                setState(() {
                  isLoading = false;
                  downloading = true;
                });
                await ytDl.videos.streamsClient.get(vid.withHighestBitrate()).pipe(vidStream);

                await for (final data in vidP) {
                  count += data.length;
                  i = ((count / len) * 100).ceil();
                  setState(() {
                    progress = i.toString();
                    print(i.toString());
                  });
                }
                setState(() {
                  downloading = false;
                });
                print("-------------DONE---------------");

              },
            ),
            SizedBox(height: 0.01 * screenSize.height),
            downloading ?
            Text(
              "$progress%",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 0.025 * screenSize.height),
            ) : Container()
            /*ListView.builder(
                shrinkWrap: true,
                itemCount: vidTitles.length,
                itemBuilder: (context, i) {
                  return Column(
                    children: [Card(child: Text(vidTitles[i]))],
                  );
                })*/
          ],
        ),
      )),
    );
  }
}
