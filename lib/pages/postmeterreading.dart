import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/models/postmeterlist_model.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';

class Postmeterreading extends StatefulWidget {
  const Postmeterreading({super.key});

  @override
  State<Postmeterreading> createState() => _PostmeterreadingState();
}

class _PostmeterreadingState extends State<Postmeterreading> {
  static const int _pageSize = 8;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<PostmeterlistModel> _posts = [];
  List<PostmeterlistModel> _filtered = [];
  bool _loading = false;
  bool _searching = false;
  bool _hasMore = true;
  int _remainingCount = 0;
  int _searchRequest = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRemainingCount();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_loadMoreWhenNearEnd);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      List<PostmeterlistModel>? newPosts =
          await PostmeterlistModel.getMasterModelList(
        limit: _pageSize,
        offset: _posts.length,
      );
      if (newPosts == null) {
        throw StateError('Could not load meter readings.');
      }

      if (!mounted) return;
      setState(() {
        _posts.addAll(newPosts);
        _filtered = _posts;
        _hasMore = newPosts.length == _pageSize;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMoreWhenNearEnd();
      });
    } catch (e) {
      print('Error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load meter readings: $e')),
      );
    }
  }

  void _loadMoreWhenNearEnd() {
    if (!_scrollController.hasClients ||
        _loading ||
        !_hasMore ||
        _searchQuery.isNotEmpty) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadData();
    }
  }

  Future<void> _loadRemainingCount() async {
    final stats = await DatabaseHelper().getReadingStats();
    if (!mounted) return;
    setState(() => _remainingCount = stats['remaining'] ?? 0);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _search(query);
  }

  Future<void> _search(String query) async {
    final request = ++_searchRequest;
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filtered = _posts;
        _searching = false;
      } else {
        _filtered = [];
        _searching = true;
      }
    });

    if (query.isEmpty) return;

    try {
      final results =
          await PostmeterlistModel.searchMasterModelList(query);
      if (!mounted || request != _searchRequest) return;
      setState(() {
        _filtered = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted || request != _searchRequest) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not search meter readings: $e')),
      );
    }
  }

  Future<void> _refreshList() async {
    setState(() {
      _posts.clear();
      _filtered.clear();
      _hasMore = true;
    });
    await _loadData();
    await _loadRemainingCount();
  }

  Widget _buildCounter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_outlined, size: 18, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            '$_remainingCount Remaining',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, account no, meter no, or address',
          hintStyle: const TextStyle(
              color: Color.fromARGB(255, 195, 186, 186), fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              'assets/icons/search.svg',
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No readings yet' : 'No matches found',
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshList,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchQuery.isEmpty
            ? _posts.length + (_hasMore ? 1 : 0)
            : _filtered.length,
        itemBuilder: (context, index) {
          if (_searchQuery.isNotEmpty && index < _filtered.length) {
            return _buildPostItem(_filtered[index], index);
          }
          if (_searchQuery.isEmpty && index < _posts.length) {
            return _buildPostItem(_posts[index], index);
          }
          return _loading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPostItem(PostmeterlistModel post, int index) {
    final tileColor = index % 2 == 0
        ? Colors.white
        : const Color.fromARGB(255, 233, 239, 252);
    return GestureDetector(
      onTap: () async {
        final shouldRefresh = await Navigator.pushNamed(
          context,
          '/consumercard',
          arguments: post.postID,
        );
        if (shouldRefresh == true && mounted) {
          _refreshList();
        }
      },
      child: Card(
        color: tileColor,
        margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.postName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.postAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    post.postMeterno,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 28, 85, 227),
        foregroundColor: Colors.white,
        title: const Text(
          'Post Meter Reading',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCounter(),
                const SizedBox(height: 8),
                _buildSearchBar(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }
}
