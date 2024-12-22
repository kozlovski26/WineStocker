import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wine_inventory/core/widgets/dismiss_keyboard_wrapper.dart';
import 'package:wine_inventory/features/wine_collection/data/repositories/wine_repository.dart';
import 'package:wine_inventory/features/wine_collection/presentation/managers/wine_manager.dart';
import 'package:wine_inventory/features/wine_collection/presentation/screens/wine_grid_screen.dart';
import 'package:wine_inventory/firebase_options.dart';
// Providers
import 'features/auth/presentation/providers/auth_provider.dart';

// Repositories
import 'features/auth/data/repositories/auth_repository.dart';

// Screens
import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'features/auth/presentation/screens/sign_up_screen.dart';

// Theme
import 'core/theme/app_theme.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DismissKeyboardWrapper(
      child: MultiProvider(
        providers: [
          Provider<AuthRepository>(
            create: (_) => AuthRepository(),
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (context) => AuthProvider(
              context.read<AuthRepository>(),
            ),
          ),
          ChangeNotifierProxyProvider<AuthProvider, WineManager?>(
            create: (_) => null,
            update: (context, authProvider, previousManager) {
              if (authProvider.user != null) {
                if (previousManager?.repository.userId != authProvider.user!.id) {
                  return WineManager(WineRepository(authProvider.user!.id));
                }
                return previousManager;
              }
              return null;
            },
          ),
        ],
        child: MaterialApp(
          title: 'Wine Collection',
          theme: AppTheme.darkTheme,
          home: const AuthWrapper(),
          onGenerateRoute: (settings) {
            if (settings.name == '/home') {
              final authProvider = context.read<AuthProvider>();
              if (authProvider.user == null) {
                return MaterialPageRoute(builder: (_) => const SignInScreen());
              }
              return MaterialPageRoute(
                builder: (_) => WineGridScreen(userId: authProvider.user!.id),
              );
            }
            switch (settings.name) {
              case '/signin':
                return MaterialPageRoute(builder: (_) => const SignInScreen());
              case '/signup':
                return MaterialPageRoute(builder: (_) => const SignUpScreen());
              default:
                return null;
            }
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return FutureBuilder(
            future: _handleFirstTimeSetup(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return WineGridScreen(userId: authProvider.user!.id);
            },
          );
        }
        return const SignInScreen();
      },
    );
  }

  Future<void> _handleFirstTimeSetup(BuildContext context) async {
    final wineManager = context.read<WineManager>();
    await wineManager.showFirstTimeSetup(context);
  }
}
