import 'dart:async';
import 'dart:io';
import 'package:clay_containers/clay_containers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:path/path.dart' as paths;
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtubedownloader/share_service.dart';
import 'package:youtubedownloader/testScreen.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.white, statusBarIconBrightness: Brightness.dark));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Music Downloader',
      home: Home(),
      theme: ThemeData(fontFamily: "Manrope"),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String searchQuery = "";
  String url = "";
  String vidTitle = "";
  String vidDuration = "";
  String downloadsPath = "storage/emulated/0/YTDownloads";
  String sharedURL = "";
  int downloadProgress = 0;
  bool isLoading = false;
  bool exceptionError = false;
  bool downloadStarted = false;
  Color baseColor = Color(0xFFf2f2f2);
  List<String> searchResults = [];
  final textController = TextEditingController();
  final progressListenable = ValueNotifier<int>(0);
  StreamController streamController = StreamController();
  YoutubeExplode ytDl = YoutubeExplode();

  ///TODO: add folder picker
  /*late Directory externalDirectory = Directory("/sdcard");*/

  Future createFolder() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
    final path = Directory(downloadsPath);
    if ((await path.exists())) {
    } else {
      path.create();
    }
  }

  initState() {
    super.initState();
    createFolder();
    ShareService()
      ..onDataReceived = _handleSharedData
      ..getSharedData().then(_handleSharedData);
  }

  void _handleSharedData(String sharedData) {
    setState(() {
      url = sharedData;
      textController.text = url;
    });
  }

  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return SafeArea(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: ValueListenableBuilder(
              valueListenable: progressListenable,
              builder: (context, i, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[

                    Container(
                      width: 0.6 * screenSize.width,
                      child: Text(
                        "Search for the music or paste the YouTube link below to download the audio.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 0.02 * screenSize.height),
                      ),
                    ),
                    SizedBox(height: 0.02 * screenSize.height),
                    Container(
                      width: 0.9 * screenSize.width,
                      child: ClayContainer(
                        emboss: true,
                        spread: 3,
                        borderRadius: 15,
                        color: baseColor,
                        child: Container(
                          margin: EdgeInsetsDirectional.fromSTEB(0.02 * screenSize.width, 0, 0.01 * screenSize.height, 0),
                          child: TextField(
                            controller: textController,
                            onChanged: (value) {
                              url = value;
                              searchQuery = value;
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 0.01 * screenSize.height,
                    ),
                    Text(sharedURL),
                    downloadStarted
                        ? Container()
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            NeumorphicButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => TestHome()));
                              },
                              style: NeumorphicStyle(
                                color: baseColor,
                                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                              ),
                              child: Text("Video"),),
                            SizedBox(width: 0.03 * screenSize.width,),
                            NeumorphicButton(
                                style: NeumorphicStyle(
                                  color: baseColor,
                                  boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                                ),
                                child: isLoading
                                    ? Container(
                                        width: 0.3 * screenSize.width,
                                        child: NeumorphicProgressIndeterminate(
                                            style: ProgressStyle(
                                          depth: -15,
                                        )))
                                    : const Text('Download'),
                                onPressed: () async {
                                  try {
                                    FocusScope.of(context).unfocus();

                                    if (isLoading) {
                                      return;
                                    } else {
                                      if (url == "" || searchQuery == '') {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(
                                            "Please enter the search query or paste a YouTube link first.",
                                            style: TextStyle(fontFamily: "Manrope"),
                                          ),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                                          duration: Duration(seconds: 5),
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      } else {
                                        setState(() {
                                          exceptionError = false;
                                          isLoading = true;
                                        });
                                        await ytDl.search.getVideos(searchQuery).then((value) => url = value[0].url);

                                        FocusScope.of(context).unfocus();

                                        var yt = YoutubeExplode();
                                        var id = VideoId(url.trim());
                                        var video = await yt.videos.get(id);

                                        setState(() {
                                          vidTitle = video.title;
                                          vidDuration = ((video.duration)).toString().replaceAll(".000000", "");
                                          isLoading = false;
                                          downloadStarted = true;
                                        });

                                        // Get the streams manifest and the audio track.
                                        var manifest = await yt.videos.streamsClient.getManifest(id);
                                        var audio = manifest.audioOnly.first;
                                        var audioStream = yt.videos.streamsClient.get(audio);

                                        // Build the directory.
                                        var filePath = paths.join(downloadsPath, '${video.title.replaceAll("|", "")}.mp3');

                                        // Open the file to write.
                                        var file = File(filePath);
                                        var fileStream = file.openWrite();

                                        var len = audio.size.totalBytes;
                                        var count = 0;

                                        await yt.videos.streamsClient.get(audio).pipe(fileStream);

                                        //Calculating the download progress
                                        await for (final data in audioStream) {
                                          count += data.length;
                                          i = ((count / len) * 100).ceil();
                                          setState(() {
                                            downloadProgress = i as int;
                                          });
                                        }

                                        setState(() {
                                          downloadStarted = false;
                                          downloadProgress = 0;
                                          url = "";
                                        });
                                        textController.clear();

                                        // Close the file.
                                        await fileStream.flush();
                                        await fileStream.close();
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(
                                            "Successfully downloaded $vidTitle",
                                            style: TextStyle(fontFamily: "Manrope"),
                                          ),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                                          duration: Duration(seconds: 3),
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                        vidTitle = "";
                                        vidDuration = "";
                                      }
                                    }
                                  } on Exception catch (_) {
                                    print("Error");
                                    setState(() {
                                      isLoading = false;
                                      exceptionError = true;
                                    });
                                    print(_.toString());
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(
                                        "Error occurred. Please paste the link and try again.",
                                        style: TextStyle(fontFamily: "Manrope"),
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                                      duration: Duration(seconds: 5),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                }),
                          ],
                        ),
                    SizedBox(height: 0.03 * screenSize.height),
                    downloadStarted
                        ? Column(
                            children: [
                              ClayContainer(
                                emboss: true,
                                spread: 3,
                                borderRadius: 15,
                                color: baseColor,
                                width: 0.9 * screenSize.width,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 0.01 * screenSize.height,
                                    ),
                                    Text(
                                      "Now Downloading,",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 0.018 * screenSize.height, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 0.03 * screenSize.height),
                                    Container(
                                      width: 0.6 * screenSize.width,
                                      child: Text(
                                        vidTitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 0.018 * screenSize.height,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 0.01 * screenSize.height,
                                    ),
                                    Container(
                                      width: 0.6 * screenSize.width,
                                      child: Text(
                                        vidDuration,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 0.018 * screenSize.height,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 0.03 * screenSize.height),
                                    downloadStarted
                                        ? Container(
                                            width: 0.6 * screenSize.width,
                                            child: NeumorphicProgress(
                                              percent: downloadProgress * 0.01,
                                              style: ProgressStyle(
                                                depth: -15,
                                              ),
                                            ),
                                          )
                                        : Container(),
                                    SizedBox(
                                      height: 0.02 * screenSize.height,
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 0.01 * screenSize.height,
                              ),
                              exceptionError
                                  ? NeumorphicButton(
                                      style: NeumorphicStyle(
                                        color: baseColor,
                                        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          downloadStarted = false;
                                          exceptionError = false;
                                          vidTitle = "";
                                        });
                                      },
                                      child: Text("Retry"),
                                    )
                                  : Container()
                            ],
                          )
                        : Container(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
