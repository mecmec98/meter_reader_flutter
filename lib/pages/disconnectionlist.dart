import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/models/disconnection_model.dart';
import 'package:meter_reader_flutter/helpers/disconnection_helper.dart';
import 'package:meter_reader_flutter/pages/disconnectiondetails.dart';

class DisconnectionList extends StatefulWidget {
  const DisconnectionList({super.key});

  @override
  State<DisconnectionList> createState() => _DisconnectionListState();
}

class _DisconnectionListState extends State<DisconnectionList> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  List<DisconnectionModel> _items = [];
  bool _loading = true;
  String _searchQuery = '';
  int _selectedSection = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final items = await DisconnectionHelper().getAllDisconnections();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
    _filter(_searchQuery);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _filter(query);
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text(
          'Disconnection List',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCounter(),
                const SizedBox(height: 12),
                _buildSearchBar(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedSection = index);
                _filter(_searchQuery);
              },
              children: [
                _buildList(isDisconnected: false),
                _buildList(isDisconnected: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildListNavigation(),
    );
  }

  Widget _buildCounter() {
    final pendingCount = _items.where((item) => item.disconReading == 0).length;
    final disconnectedCount =
        _items.where((item) => item.disconReading != 0).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Text(
            'Pending: $pendingCount  •  Disconnected: $disconnectedCount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
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

  Widget _buildList({required bool isDisconnected}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    var items = _items
        .where((item) => (item.disconReading != 0) == isDisconnected)
        .toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((item) {
        return item.name.toLowerCase().contains(q) ||
            item.accNo.toLowerCase().contains(q) ||
            item.metNo.toLowerCase().contains(q) ||
            item.address.toLowerCase().contains(q);
      }).toList();
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? (isDisconnected
                  ? 'No disconnected records'
                  : 'No pending disconnection records')
              : 'No matches found',
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final disconnected = item.disconReading != 0;
          final tileColor = index % 2 == 0
              ? Colors.white
              : disconnected
                  ? const Color.fromARGB(255, 255, 232, 232)
                  : const Color.fromARGB(255, 255, 243, 243);
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DisconnectionDetailsPage(item: item),
                ),
              );
              if (mounted) await _loadData();
            },
            child: Card(
              color: tileColor,
              margin: const EdgeInsets.only(bottom: 8),
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
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: disconnected
                                ? Colors.red
                                : Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '₱${item.balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: disconnected
                                  ? Colors.white
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.accNo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListNavigation() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: BottomNavigationBar(
          currentIndex: _selectedSection,
          onTap: (index) {
            setState(() => _selectedSection = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.red.shade700,
          unselectedItemColor: const Color(0xFF8A8178),
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined),
              activeIcon: Icon(Icons.schedule),
              label: 'Pending',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Disconnected',
            ),
          ],
        ),
      ),
    );
  }
}
