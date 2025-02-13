import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  AppUser? _user;
  bool _isLoading = false;
  StreamSubscription<AppUser?>? _authSubscription;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  AuthProvider(this._authRepository) {
    _initAuthState();
  }

  void _initAuthState() {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) {
        print('Auth state changed: ${user?.id}'); // Debug log
        _user = user;
        notifyListeners();
      },
      onError: (error) {
        print('Auth state error: $error'); // Debug log
        _user = null;
        notifyListeners();
      }
    );
  }

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

Future<void> signIn(String email, String password) async {
  try {
    print('AuthProvider: Starting sign in process...'); // Debug log
    _isLoading = true;
    notifyListeners();
    
    final user = await _authRepository.signInWithEmailAndPassword(
      email, 
      password,
    );
    
    print('AuthProvider: Sign in successful, user: ${user?.id}'); // Debug log
    _user = user;
    notifyListeners();
    print('AuthProvider: Notified listeners after sign in'); // Debug log
  } catch (e) {
    print('AuthProvider: Sign in error: $e'); // Debug log
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
    print('AuthProvider: Sign in process completed'); // Debug log
  }
}

  Future<void> signUp(
  String email, 
  String password, 
  String firstName, 
  String lastName
) async {
  try {
    _isLoading = true;
    notifyListeners();
    
    final user = await _authRepository.createUserWithEmailAndPassword(
      email, 
      password,
      firstName,
      lastName
    );
    
    _user = user;
    notifyListeners();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authRepository.signOut();
      _user = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _authRepository.deleteAccount();
      
      _user = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred.',
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
