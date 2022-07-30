import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yt_songs/database_song.dart';
import 'package:yt_songs/downloader_callback.dart';
import 'package:yt_songs/loading.dart';
import 'package:yt_songs/song.dart';
import 'shared_data.dart';
import 'package:http/http.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  ReceivePort _port = ReceivePort();
  TextEditingController searchController = TextEditingController();
  ScrollController listScrollController = ScrollController();
  InAppWebViewController? webViewController;
  List<Song> songs = [];
  List<Song> queue = [];
  List<Song> songsBeingDownloaded = [];
  int page = 0;
  int currentlyLinkSearching = 0;
  int lastDownloaded = -1;
  String currentSearchUrl = "";
  bool loading = false;
  bool fetchingMoreSongs = false;


  @override
  void initState() {
    init();
  }

  void init() async{
    WidgetsFlutterBinding.ensureInitialized();
    await FlutterDownloader.initialize();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(DownloaderCallback.callbackDownloader);
    requestPersmission();
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      if(data[1] == DownloadTaskStatus.complete){
        Song downloadedSong = queue.firstWhere((element) => element.downloadTaskId == data[0]);
        SharedData.databaseManager.insertSong(DatabaseSong.withoutId(
            downloadedSong.url, downloadedSong.title, downloadedSong.duration, downloadStatus.success));
        SharedData.downloadedSongs.add(DatabaseSong.withoutId(
            downloadedSong.url, downloadedSong.title, downloadedSong.duration, downloadStatus.success));
        setState((){

        });
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_port');
  }


  Future<void> search() async {
    songs = [];
    page = 0;
    String baseUrl = "https://www.google.com/search?q=%22youtube.com%2Fwatch%3Fv%3D%22+";
    currentSearchUrl = baseUrl + Uri.encodeFull(searchController.text);
    String urlString = currentSearchUrl.replaceAll("%20", "+").replaceAll("&", "%26");
    urlString = urlString + "&start=" + page.toString() + "&tbm=vid";
    var response = await get(Uri.parse(urlString));
    if(response.statusCode == 200){
      String htmlDocument = response.body;
      scrape(htmlDocument);
    }
    turnOffLoading();
  }

  void loadMore() async {
    fetchingMoreSongs = true;
    page += 10;
    String urlString = currentSearchUrl.replaceAll("%20", "+").replaceAll("&", "%26");
    urlString = urlString + "&start=" + page.toString() + "&tbm=vid";
    var response = await get(Uri.parse(urlString));
    if(response.statusCode == 200){
      String htmlDocument = response.body;
      scrape(htmlDocument);
    }
    turnOffLoading();
    fetchingMoreSongs = false;
  }

  void tidyScreen(){
    FocusManager.instance.primaryFocus?.unfocus();
    final position = listScrollController.position.minScrollExtent;
    listScrollController.jumpTo(position);
  }

  void scrape(String html){
    String str1 = "href=\"/url?q=https://www.youtube.com/watch%3Fv%3D";
    String str2 = "<div";
    bool linkFound = false;
    bool titleFound = false;
    String url = "";
    String title = "";
    String duration = "";

    for(int i = 10000; i < html.length - 20000; i++){


      if(!linkFound && html.substring(i, i + str1.length) == str1){
        linkFound = true;
        url = "https://youtube.com/watch?v=" + html.substring(i + str1.length, i + str1.length + 11);
      }

      if(linkFound && !titleFound && html.substring(i, i + str2.length) == str2){
        titleFound = true;
        while(html.substring(i, i + 1) != ">")
          i++;
        int titleStart = ++i;
        while(html.substring(i, i + 6) != "</div>")
          i++;
        int titleEnd = i;
        title = HtmlUnescape().convert(html.substring(titleStart, titleEnd));
      }
      
      if(linkFound && titleFound){
        linkFound = false;
        titleFound = false;
        for(int j = 0; j < 3; j++){
          while(html.substring(i, i + 5) != "<span")
            i++;
          i++;
        }
        while(html.substring(i, i + 1) != ">")
          i++;
        int durStart = ++i;
        while(html.substring(i, i + 1) != "<")
          i++;
        int durEnd = i;
        duration = html.substring(durStart, durEnd);
        setState(() {
          songs.add(Song(url, title, duration));
        });
      }
    }
  }

  void afterDownloadLinkFound(String link) async {
    print(link);
    int indexInQueue = currentlyLinkSearching;
    currentlyLinkSearching ++;
    if(currentlyLinkSearching == queue.length){
      webViewController!.loadUrl(urlRequest: URLRequest(url: Uri.parse("about:blank")));
    }
    else{
      webViewController!.loadUrl(urlRequest: URLRequest(url: Uri.parse(queue[currentlyLinkSearching].url)));
    }
    queue[indexInQueue].downloadTaskId = await FlutterDownloader.enqueue(
        url: link,
        //savedDir: "/storage/sdcard0/Music",
        savedDir: "/storage/emulated/0/Music",
        fileName: queue[indexInQueue].title + ".mp3");
    setState((){
      songsBeingDownloaded.add(queue.elementAt(currentlyLinkSearching - 1));
    });
  }

  void onItemTapped(Song song){
    if(!songInQueue(song)) {// download
      queue.add(song);
      if (currentlyLinkSearching == queue.length - 1 && song.url != "") {
        webViewController!.loadUrl(
            urlRequest: URLRequest(url: Uri.parse(song.url)));
      }
    }

    //TODO: cancel if download link is just about to be found
    else{ //cancel download
      if(songBeingDownloaded(song)){
        FlutterDownloader.cancel(taskId: song.downloadTaskId!);
        removeFromQueue(song);
        songsBeingDownloaded.removeAt(songsBeingDownloaded.indexWhere((element) => element.downloadTaskId == song.downloadTaskId));
      }
      else{
        removeFromQueue(song);
      }
    }

    setState((){
    });
  }

  void requestPersmission() async {
    var status = await Permission.storage.status;
    if (status.isGranted == false) {
      // You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
    }
  }


  void turnOnLoading() {
    setState(() {
      loading = true;
    });
  }

  void turnOffLoading() {
    setState(() {
      loading = false;
    });
  }

  void cancelLoading(){
    turnOffLoading();
    //TODO: cancel searching / loading more
    if(fetchingMoreSongs){

    }
    else{

    }
  }

  bool songAlreadyDownloaded(Song currentSong){
    String url = currentSong.url;
    return SharedData.downloadedSongs.map((e) => e.url).contains(url);
  }

  bool songBeingDownloaded(Song currentSong){
    String url = currentSong.url;
    return songsBeingDownloaded.map((e) => e.url).contains(url);
  }

  bool songInQueue(Song currentSong){
    String url = currentSong.url;
    return queue.map((e) => e.url).contains(url);
  }

  void removeFromQueue(Song song){
    String url = song.url;
    queue.removeAt(queue.indexWhere((element) => element.url == url));
    currentlyLinkSearching --;
  }




  @override
  Widget build(BuildContext context) {

    SharedData.deviceWidth = MediaQuery.of(context).size.width;
    SharedData.deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: loading ? LoadingScreen(cancelLoading: cancelLoading,) : Column(
        children: [
          SizedBox(height: SharedData.deviceHeight * 0.02,),
          Row(
            children: [
              SizedBox(width: SharedData.deviceWidth * 0.05,),
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value){
                    turnOnLoading();
                    tidyScreen();
                    search();
                  },
                ),
              ),
              SizedBox(width: SharedData.deviceWidth * 0.025,),
              TextButton(onPressed: (){
                setState(() {
                  turnOnLoading();
                  tidyScreen();
                  search();
                });
              },
                  child: Text("Search")),
              SizedBox(width: SharedData.deviceWidth * 0.05,),
            ],
          ),
          Visibility(
            visible: false,
              maintainState: true,
              child: SizedBox(
                height: 1,
                child: InAppWebView(initialUrlRequest: URLRequest(url: Uri.parse("about:blank")),
                 initialOptions: InAppWebViewGroupOptions(
                   android: AndroidInAppWebViewOptions(useShouldInterceptRequest: true)
                 ),
                  onWebViewCreated: (controller) {
                  webViewController = controller;
                  },
                  androidShouldInterceptRequest: (controller, request) async {
                    String link = request.url.toString();
                    if (link.contains("googlevideo.com") && link.contains("&mime=audio") && link.contains("&range=")) {
                      afterDownloadLinkFound(link.substring(0, link.indexOf("&range=")));
                    }
                    return null;
                  },
                ),
              )
          ),
          Expanded(
            child: ListView.builder(
              controller: listScrollController,
                itemCount: songs.length == 0 ? 0 : songs.length + 1,
                itemBuilder: (context, position){
              return GestureDetector(
                onTap: (){
                  if(position == songs.length){
                    turnOnLoading();
                    loadMore();
                  }
                  else{
                    onItemTapped(songs[position]);
                  }
                },
                child: Card(
                  margin: EdgeInsets.fromLTRB(SharedData.deviceWidth * 0.03, SharedData.deviceHeight * 0.01,
                      SharedData.deviceWidth * 0.03, 0),
                  child: Padding(
                    padding: EdgeInsets.all(SharedData.deviceWidth * 0.03),
                    child: position >= songs.length ?
                    Row(
                      children: [
                        Spacer(),
                        Text("Load more", style: TextStyle(fontWeight: FontWeight.bold),),
                        Spacer(),
                      ],
                    ) :
                    Row(
                      children: [
                        songAlreadyDownloaded(songs[position]) ?
                          Icon(Icons.save, color: Color.fromRGBO(0, 160, 10, 1), size: SharedData.deviceWidth * 0.05) : //downloaded
                          (songBeingDownloaded(songs[position]) ?
                            Icon(Icons.save_alt_outlined, color: Color.fromRGBO(240, 235, 0, 1), size: SharedData.deviceWidth * 0.05) : //downloading
                            (songInQueue(songs[position]) ?
                              Icon(Icons.access_time, color: Color.fromRGBO(0, 30, 220, 1), size: SharedData.deviceWidth * 0.05) : //in queue
                              Icon(Icons.access_time, color: Color.fromRGBO(0, 0, 0, 0), size: SharedData.deviceWidth * 0.05))), //empty icon
                        //Icon(Icons.access_time, color: Color.fromRGBO(0, 10, 80, 1), size: SharedData.deviceWidth * 0.05),
                        SizedBox(width: SharedData.deviceWidth * 0.03,),
                        Expanded(
                            child: Text(songs[position].title, maxLines: 2, overflow: TextOverflow.ellipsis,)),
                        SizedBox(width: SharedData.deviceWidth * 0.03,),
                        Text(songs[position].duration),
                      ],
                    ),
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}