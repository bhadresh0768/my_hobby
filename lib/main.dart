import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'common/theme/app_theme.dart';
import 'app/screens/main_navigation_screen.dart';
import 'app/bloc/auth/auth_bloc.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/business_repository.dart';
import 'app/bloc/business/business_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<BusinessRepository>(create: (_) => BusinessRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(authRepository: context.read<AuthRepository>()),
          ),
          BlocProvider<BusinessBloc>(
            create: (context) => BusinessBloc(businessRepository: context.read<BusinessRepository>()),
          ),
        ],
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
      
      // Root Screen: Always start with Navigation (Guest Friendly)
      home: const MainNavigationScreen(),
    );
  }
}
