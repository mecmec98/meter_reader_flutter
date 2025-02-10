import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/models/postmeterlist_model.dart';

class Postmeterreading extends StatefulWidget {
  const Postmeterreading({super.key});

  @override
  State<Postmeterreading> createState() => _PostmeterreadingState();
}

class _PostmeterreadingState extends State<Postmeterreading> {
  late Future<List<PostmeterlistModel>> _postmeterListFuture;

  @override
  void initState() {
    super.initState();
    _postmeterListFuture = PostmeterlistModel.getMasterModelList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: postAppbar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchBar(),
          SizedBox(height: 5.0,),
          postMeterList()
        ],
      ),
    );
  }

  FutureBuilder<List<PostmeterlistModel>> postMeterList() {
    return FutureBuilder<List<PostmeterlistModel>>(
          future: _postmeterListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No data available"));
            }

            final postmeterList = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: postmeterList.length,
              itemBuilder: (context, index) {
                final post = postmeterList[index];
                // Determine the background color based on the index
                final Color tileColor =
                    index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                return Card(
                  margin:
                      EdgeInsets.only(top: 4, left: 8, right: 8, bottom: 4),
                  color: tileColor,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.postName,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          post.postMeterno,
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
                        ),
                        Text(
                          post.postAddress,
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
  }

  Container searchBar() {
    return Container(
      margin: EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Color.fromARGB(255, 230, 223, 223).withValues(),
          blurRadius: 8,
          spreadRadius: 0.0,
        )
      ]),
      child: TextField(
          decoration: InputDecoration(
        hintText: 'Search',
        hintStyle: TextStyle(color: Color.fromARGB(255, 195, 186, 186)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SvgPicture.asset(
            'assets/icons/search.svg',
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
          ),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none),
      )),
    );
  }

  AppBar postAppbar(BuildContext context) {
    return AppBar(
      title: Text(
        'Post Meter Reading',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/');
        },
        child: Container(
          margin: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/arrow-left.svg',
            height: 25,
            width: 25,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
