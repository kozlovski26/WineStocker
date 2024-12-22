import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:wine_inventory/features/auth/presentation/providers/auth_provider.dart';
import 'user_collection_screen.dart';

class BrowseUsersScreen extends StatelessWidget {
  const BrowseUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
     final currentUserId = Provider.of<AuthProvider>(context).user?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Collections'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users')
             .where('id', isNotEqualTo: currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final displayName = userData['displayName'] ?? 'Anonymous User';
              final photoUrl = userData['photoUrl'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(displayName),
                trailing: const Icon(Icons.arrow_forward_ios),
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
              );
            },
          );
        },
      ),
    );
  }
}