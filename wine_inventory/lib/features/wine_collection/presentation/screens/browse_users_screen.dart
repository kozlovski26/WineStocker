import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:wine_inventory/features/auth/presentation/providers/auth_provider.dart';
import 'user_collection_screen.dart';

class BrowseUsersScreen extends StatefulWidget {
  const BrowseUsersScreen({super.key});

  @override
  State<BrowseUsersScreen> createState() => _BrowseUsersScreenState();
}

class _BrowseUsersScreenState extends State<BrowseUsersScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showOnlyWithWines = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int> _getBottleCount(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wines')
        .where('isDrunk', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).user?.id;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Browse Collections'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search collections...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.wine_bar,
                  size: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Show only collections with wines',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _showOnlyWithWines,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyWithWines = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                  activeTrackColor: Theme.of(context).primaryColor.withOpacity(0.3),
                  inactiveThumbColor: isDarkMode ? Colors.grey[400] : Colors.grey[100],
                  inactiveTrackColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('id', isNotEqualTo: currentUserId)
                  .orderBy('id')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs.where((doc) {
                  final userData = doc.data() as Map<String, dynamic>;
                  final displayName = userData['displayName']?.toString().toLowerCase() ?? '';
                  return displayName.contains(_searchQuery);
                }).toList();

                return FutureBuilder<List<MapEntry<String, int>>>(
                  future: Future.wait(
                    users.map((user) async {
                      final bottleCount = await _getBottleCount(user.id);
                      return MapEntry(user.id, bottleCount);
                    }),
                  ),
                  builder: (context, bottleCountSnapshot) {
                    if (!bottleCountSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userBottleCounts = Map.fromEntries(bottleCountSnapshot.data!);
                    final filteredUsers = users.where((user) {
                      final bottleCount = userBottleCounts[user.id] ?? 0;
                      return !_showOnlyWithWines || bottleCount > 0;
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? _showOnlyWithWines 
                                  ? 'No collections with wines found'
                                  : 'No collections found'
                              : 'No collections found matching "$_searchQuery"',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final userData = filteredUsers[index].data() as Map<String, dynamic>;
                        final userId = filteredUsers[index].id;
                        final displayName = userData['displayName'] ?? 'Anonymous User';
                        final photoURL = userData['photoURL'];

                        return Card(
                          elevation: 2,
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserCollectionScreen(
                                    userId: userId,
                                    userName: displayName,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Hero(
                                    tag: 'profile_$userId',
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: photoURL != null
                                            ? CachedNetworkImage(
                                                imageUrl: photoURL,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 30,
                                                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) =>
                                                    const Icon(Icons.error),
                                              )
                                            : Container(
                                                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                                child: Icon(
                                                  Icons.person,
                                                  size: 30,
                                                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FutureBuilder<int>(
                                          future: _getBottleCount(userId),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const SizedBox.shrink();
                                            }
                                            final bottleCount = snapshot.data ?? 0;
                                            return Row(
                                              children: [
                                                Icon(
                                                  bottleCount > 0 
                                                      ? Icons.wine_bar
                                                      : Icons.wine_bar_outlined,
                                                  size: 16,
                                                  color: bottleCount > 0
                                                      ? Theme.of(context).primaryColor
                                                      : isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  bottleCount > 0
                                                      ? '$bottleCount bottles'
                                                      : 'No bottles',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: bottleCount > 0
                                                        ? (isDarkMode ? Colors.grey[300] : Colors.grey[700])
                                                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: isDarkMode ? Colors.grey[400] : Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}