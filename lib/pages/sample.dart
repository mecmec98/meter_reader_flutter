import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/models/postmeterlist_model.dart';

class PostmeterListScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _PostmeterListScreenState createState() => _PostmeterListScreenState();
}

class _PostmeterListScreenState extends State<PostmeterListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<PostmeterlistModel> _posts = [];
  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 8;
  bool _hasMore = true; // flag to know if more data is available

  @override
  void initState() {
    super.initState();
    _loadData(); // load the first page
    _scrollController.addListener(() {
      // When scroll reaches near the bottom and more data is available, load the next page
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
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
        await PostmeterlistModel.getMasterModelList(limit: _limit, offset: _offset);

    setState(() {
      _posts.addAll(newPosts);
      _offset += newPosts.length; // update offset
      _isLoading = false;
      // if fewer items were returned than the limit, there are no more items
      if (newPosts.length < _limit) {
        _hasMore = false;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildPostItem(PostmeterlistModel post, int index) {
    // Alternate the background color
    final Color tileColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;

    return Card(
      color: tileColor,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.postName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              post.postAddress,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8.0),
            Text(
              "Meter Number: ${post.postMeterno}",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Postmeter List")),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _posts.length + 1, // add one for the loading indicator
        itemBuilder: (context, index) {
          if (index < _posts.length) {
            return _buildPostItem(_posts[index], index);
          } else {
            // Show a loading indicator at the bottom if more data is loading
            return _hasMore
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox.shrink();
          }
        },
      ),
    );
  }
}
