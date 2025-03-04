import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/models/postmeterlist_model.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';

//PostmeterReading List
class Postmeterreading extends StatefulWidget {
  @override
  State<Postmeterreading> createState() => _PostmeterreadingState();
}

class _PostmeterreadingState extends State<Postmeterreading> {
  final ScrollController _scrollController = ScrollController();
  List<PostmeterlistModel> _posts = [];
  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 8;
  bool _hasMore = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(() {
      // Only paginate if there is no active search.
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore &&
          _searchQuery.isEmpty) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    // Fetch the next page
    List<PostmeterlistModel> newPosts =
        await PostmeterlistModel.getMasterModelList(
            limit: _limit, offset: _offset);

    setState(() {
      _posts.addAll(newPosts);
      _offset += newPosts.length; // update offset
      _isLoading = false;
      if (newPosts.length < _limit) {
        _hasMore = false;
      }
    });
  }

  /// Search the database using the given query.
  Future<void> _searchData(String query) async {
    setState(() {
      _searchQuery = query;
    });

    // If the search query is empty, reload the paginated data.
    if (query.isEmpty) {
      setState(() {
        _posts.clear();
        _offset = 0;
        _hasMore = true;
      });
      await _loadData();
    } else {
      setState(() {
        _isLoading = true;
      });
      // Query the database using the search function.
      List<Map<String, dynamic>> results =
          await DatabaseHelper().searchMasterData(query);
      // Convert results into your model.
      // Assumes PostmeterlistModel.fromMap exists.
      List<PostmeterlistModel> searchResults =
          results.map((map) => PostmeterlistModel.fromMap(map)).toList();
      setState(() {
        _posts = searchResults;
        _isLoading = false;
        // Disable pagination while showing search results.
        _hasMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshList() async {
    setState(() {
      _posts.clear();
      _offset = 0;
      _hasMore = true;
    });
    await _loadData();
  }

  Widget _buildPostItem(PostmeterlistModel post, int index) {
    // Alternate the background color.
    final Color tileColor = index % 2 == 0
        ? Colors.white
        : const Color.fromARGB(255, 212, 224, 250);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/consumercard',
          arguments: post.postID,
        );
        _refreshList();
      },
      child: Card(
        color: tileColor,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.postName,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                post.postMeterno,
                style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w400),
              ),
              Text(
                post.postAddress,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListView postMeterLists() {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: _posts.length + 1, // add one for the loading indicator
      itemBuilder: (context, index) {
        if (index < _posts.length) {
          return _buildPostItem(_posts[index], index);
        } else {
          return _hasMore
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }
      },
    );
  }

  Container searchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 15, left: 20, right: 20),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          // ignore: deprecated_member_use
          color: const Color.fromARGB(255, 230, 223, 223).withOpacity(0.5),
          blurRadius: 8,
          spreadRadius: 0.0,
        )
      ]),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(color: Color.fromARGB(255, 195, 186, 186)),
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
        ),
        onChanged: (value) {
          _searchData(value);
        },
      ),
    );
  }

  AppBar postAppbar(BuildContext context) {
    return AppBar(
      title: const Text(
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
          margin: const EdgeInsets.all(10),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: postAppbar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchBar(),
          const SizedBox(height: 5.0),
          Expanded(child: postMeterLists()),
        ],
      ),
    );
  }
}
