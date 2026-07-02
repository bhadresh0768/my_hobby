import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'common/theme/app_theme.dart';
import 'app/screens/home_screen.dart';
import 'app/screens/auth/login_screen.dart';
import 'app/bloc/auth/auth_bloc.dart';
import 'app/bloc/auth/auth_state.dart';
import 'core/repositories/auth_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    Provider<AuthRepository>(
      create: (_) => AuthRepository(),
      child: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(authRepository: context.read<AuthRepository>()),
        child: const BusinessDiaryApp(),
      ),
    ),
  );
}

class BusinessDiaryApp extends StatelessWidget {
  const BusinessDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Diary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Localization Support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('hi', ''), // Hindi
      ],
      
      // Root Screen with Auth State Management
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            return const HomeScreen();
          }
          if (state.status == AuthStatus.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
