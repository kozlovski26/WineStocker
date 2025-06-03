import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../wine_collection/data/repositories/wine_repository.dart';

class ProfilePage extends StatefulWidget {
  final WineRepository repository;
  
  const ProfilePage({
    super.key,
    required this.repository,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _profileImageUrl;
  File? _imageFile;
  final _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  bool _isPro = false;
  bool _canBrowseCollections = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await widget.repository.getUserData();
      final isPro = await widget.repository.isUserPro();
      final canBrowseCollections = await widget.repository.canBrowseAllCollections();
      
      setState(() {
        _firstNameController.text = userData['firstName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _profileImageUrl = userData['photoURL'];
        _isAdmin = userData['isAdmin'] == true;
        _isPro = isPro;
        _canBrowseCollections = canBrowseCollections;
      });
    } catch (e) {
      print('Error loading user data: $e');
      _showErrorSnackBar('Error loading user data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Limit image size
        maxHeight: 800,
        imageQuality: 85, // Compress image
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          print('Image picked: ${pickedFile.path}'); // Debug log
        });
      }
    } catch (e) {
      print('Error picking image: $e'); // Debug log
      _showErrorSnackBar('Error picking image');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? newPhotoURL = _profileImageUrl;
      
      if (_imageFile != null) {
        print('Uploading new profile image');
        try {
          newPhotoURL = await widget.repository.uploadProfileImage(_imageFile!.path);
          if (newPhotoURL == null) {
            throw Exception('Failed to upload profile image');
          }
          print('New image URL: $newPhotoURL');
          
          // Update state with new image URL
          setState(() {
            _profileImageUrl = newPhotoURL;
            _imageFile = null; // Clear the file after successful upload
          });
        } catch (e) {
          print('Error uploading image: $e');
          _showErrorSnackBar('Error uploading image. Please try again.');
          return;
        }
      }

      final displayName = '${_firstNameController.text} ${_lastNameController.text}'.trim();
      
      await widget.repository.updateUserProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        displayName: displayName,
        photoURL: newPhotoURL,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        _showErrorSnackBar('Error updating profile. Please try again.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('New passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Reauthenticate user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        
        // Update password
        await user.updatePassword(_newPasswordController.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear password fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        }
      }
    } catch (e) {
      String message = 'Error updating password';
      if (e is FirebaseAuthException) {
        message = switch (e.code) {
          'wrong-password' => 'Current password is incorrect',
          'weak-password' => 'New password is too weak',
          _ => 'Error updating password: ${e.message}',
        };
      }
      _showErrorSnackBar(message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildAdminControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current User Permissions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Pro Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pro Status'),
                Switch(
                  value: _isPro,
                  onChanged: (value) async {
                    try {
                      await widget.repository.toggleUserProStatus(
                        widget.repository.userId,
                        value,
                      );
                      setState(() => _isPro = value);
                      _showSuccessSnackBar(
                        value ? 'Pro status enabled' : 'Pro status disabled',
                      );
                    } catch (e) {
                      _showErrorSnackBar('Error updating Pro status');
                    }
                  },
                ),
              ],
            ),
            
            // Collection Browsing Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Browse Collections'),
                Switch(
                  value: _canBrowseCollections,
                  onChanged: (value) async {
                    try {
                      await widget.repository.toggleCollectionBrowsingStatus(
                        widget.repository.userId,
                        value,
                      );
                      setState(() => _canBrowseCollections = value);
                      _showSuccessSnackBar(
                        value 
                          ? 'Collection browsing enabled' 
                          : 'Collection browsing disabled',
                      );
                    } catch (e) {
                      _showErrorSnackBar('Error updating collection browsing');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : _profileImageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(_profileImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: _imageFile == null && _profileImageUrl == null
                                ? const Center(
                                    child: Icon(Icons.person, size: 50),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email (non-editable)
                    Text(
                      _auth.currentUser?.email ?? 'No email',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),

                    // First Name Field
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Last Name Field
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Update Profile'),
                    ),
                    const Divider(height: 48),

                    // Password Change Section
                    Text(
                      'Change Password',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updatePassword,
                      child: const Text('Update Password'),
                    ),
                    
                    // Admin Section
                    if (_isAdmin) ...[
                      const Divider(height: 48),
                      Text(
                        'Admin Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildAdminControls(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 