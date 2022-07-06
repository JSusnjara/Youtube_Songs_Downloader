import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yt_songs/downloader_callback.dart';
import 'package:yt_songs/song.dart';
import 'local_data.dart';
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

  TextEditingController searchController = TextEditingController();
  ScrollController listScrollController = ScrollController();
  InAppWebViewController? webViewController;
  List<Song> songs = [];
  List<Song> queue = [];
  int page = 0;
  int currentlyLinkSearching = 0;
  int lastDownloaded = -1;
  String currentSearchUrl = "";


  @override
  void initState() {
    init();
  }

  void init() async{
    WidgetsFlutterBinding.ensureInitialized();
    await FlutterDownloader.initialize();
    FlutterDownloader.registerCallback(DownloaderCallback.callbackDownloader);
    requestPersmission();
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
  }

  void loadMore() async {
    page += 10;
    String urlString = currentSearchUrl + "&start=" + page.toString();
    urlString = urlString.replaceAll("%20", "+").replaceAll("&", "%26") + "&tbm=vid";
    var response = await get(Uri.parse(urlString));
    if(response.statusCode == 200){
      String htmlDocument = response.body;
      scrape(htmlDocument);
    }
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
  }

  void onItemTapped(Song song){
    queue.add(song);
    if(currentlyLinkSearching == queue.length - 1){
      webViewController!.loadUrl(urlRequest: URLRequest(url: Uri.parse(song.url)));
    }
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



  @override
  Widget build(BuildContext context) {

    LocalData.deviceWidth = MediaQuery.of(context).size.width;
    LocalData.deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: Column(
        children: [
          SizedBox(height: LocalData.deviceHeight * 0.02,),
          Row(
            children: [
              SizedBox(width: LocalData.deviceWidth * 0.05,),
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value){
                    tidyScreen();
                    search();
                  },
                ),
              ),
              SizedBox(width: LocalData.deviceWidth * 0.025,),
              TextButton(onPressed: (){
                setState(() {
                  tidyScreen();
                  search();
                });
              },
                  child: Text("Search")),
              SizedBox(width: LocalData.deviceWidth * 0.05,),
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
                    loadMore();
                  }
                  else{
                    onItemTapped(songs[position]);
                  }
                },
                child: Card(
                  margin: EdgeInsets.fromLTRB(LocalData.deviceWidth * 0.03, LocalData.deviceHeight * 0.01,
                      LocalData.deviceWidth * 0.03, 0),
                  child: Padding(
                    padding: EdgeInsets.all(LocalData.deviceWidth * 0.03),
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
                        Expanded(
                            child: Text(songs[position].title, maxLines: 2, overflow: TextOverflow.ellipsis,)),
                        SizedBox(width: LocalData.deviceWidth * 0.03,),
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