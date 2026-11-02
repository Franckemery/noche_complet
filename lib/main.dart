import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'services/story_service.dart';

final onboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_done') ?? false;
});

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Handler background FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  timeago.setLocaleMessages('fr', timeago.FrMessages());

  await NotificationService.init();
  StoryService().deleteExpiredStories();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Noche',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final onboardingAsync = ref.watch(onboardingProvider);

    return onboardingAsync.when(
      data: (onboardingDone) {
        if (!onboardingDone) {
          FlutterNativeSplash.remove();
          return const OnboardingScreen();
        }

        return authState.when(
          data: (user) {
            FlutterNativeSplash.remove();
            if (user != null && user.emailVerified) {
              NotificationService.saveTokenToFirestore(user.uid)
                  .then((_) async {
                final token = await FirebaseMessaging.instance.getToken();
                debugPrint('=============================');
                debugPrint('FCM TOKEN: $token');
                debugPrint('=============================');
              });
              return const MainScreen();
            }
            return const LoginScreen();
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) {
            FlutterNativeSplash.remove();
            return const LoginScreen();
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) {
        FlutterNativeSplash.remove();
        return const LoginScreen();
      },
    );
  }
}






// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:timeago/timeago.dart' as timeago;
// import 'firebase_options.dart';
// import 'core/constants/app_theme.dart';
// import 'providers/theme_provider.dart';
// import 'providers/auth_provider.dart';
// import 'screens/auth/login_screen.dart';
// import 'screens/home/home_screen.dart';
// import 'screens/main_screen.dart';
// import 'services/notification_service.dart';

// void main() async {
//   final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
//   FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
//   //notifications
//   await NotificationService.init();
  
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   timeago.setLocaleMessages('fr', timeago.FrMessages());

//   runApp(const ProviderScope(child: MyApp()));
// }

// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final themeMode = ref.watch(themeProvider);

//     return MaterialApp(
//       title: 'Noche',
//       debugShowCheckedModeBanner: false,
//       themeMode: themeMode,
//       theme: AppTheme.light,
//       darkTheme: AppTheme.dark,
//       home: const AuthWrapper(),
//     );
//   }
// }

// class AuthWrapper extends ConsumerWidget {
//   const AuthWrapper({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final authState = ref.watch(authStateProvider);

//     return authState.when(
//       data: (user) {
//         FlutterNativeSplash.remove();
//         if (user != null && user.emailVerified) {
//           return const MainScreen();
//         }
//         return const LoginScreen();
//       },
//       loading: () => const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       ),
//       error: (_, __) {
//         FlutterNativeSplash.remove();
//         return const LoginScreen();
//       },
//     );
//   }
// }