import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'local_data.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  @override
  Widget build(BuildContext context) {

    LocalData.deviceWidth = MediaQuery.of(context).size.width;
    LocalData.deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
    );
  }
}
