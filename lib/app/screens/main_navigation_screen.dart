import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../common/models/user_model.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/auth/auth_event.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'auth/login_screen.dart';
import 'auth/edit_profile_screen.dart';
import 'business/my_businesses_screen.dart';
import 'user/my_claims_screen.dart';
import '../bloc/locale/locale_cubit.dart';
import '../../l10n/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  List<Widget> _getWidgetOptions(AuthState state) {
    final List<Widget> options = [
      const HomeScreen(),
      const FavoritesScreen(),
      const MyClaimsScreen(),
    ];

    if (state.user?.role == UserRole.businessOwner) {
      options.add(const MyBusinessesScreen());
    }

    options.add(const _ProfileWrapper());
    return options;
  }

  List<BottomNavigationBarItem> _getNavItems(AuthState state) {
    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: AppLocalizations.of(context)!.home,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.favorite_outline),
        activeIcon: const Icon(Icons.favorite),
        label: AppLocalizations.of(context)!.favorites,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.local_offer_outlined),
        activeIcon: const Icon(Icons.local_offer),
        label: AppLocalizations.of(context)!.offers,
      ),
    ];

    if (state.user?.role == UserRole.businessOwner) {
      items.add(BottomNavigationBarItem(
        icon: const Icon(Icons.business_center_outlined),
        activeIcon: const Icon(Icons.business_center),
        label: AppLocalizations.of(context)!.myBusiness,
      ));
    }

    items.add(BottomNavigationBarItem(
      icon: const Icon(Icons.person_outline),
      activeIcon: const Icon(Icons.person),
      label: AppLocalizations.of(context)!.profile,
    ));

    return items;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current.status == AuthStatus.error,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // 1. Initial Loading (App Start)
          if (state.status == AuthStatus.initial ||
              (state.status == AuthStatus.loading && state.user == null && state.phoneNumber == null)) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 2. Login Flow (Unauthenticated or currently authenticating)
          final bool isAuthenticating = state.status == AuthStatus.codeSent ||
              state.status == AuthStatus.loading ||
              state.status == AuthStatus.error;

          if (!state.isGuest &&
              state.user == null &&
              (state.status == AuthStatus.unauthenticated || isAuthenticating)) {
            return const LoginScreen();
          }

          // 3. Main App UI (Authenticated or Guest)
          final widgetOptions = _getWidgetOptions(state);
          final navItems = _getNavItems(state);

          // Safety check for index out of bounds if role changes
          if (_selectedIndex >= widgetOptions.length) {
            _selectedIndex = widgetOptions.length - 1;
          }

          return Scaffold(
            body: Center(
              child: widgetOptions.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: navItems,
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              onTap: _onItemTapped,
            ),
          );
        },
      ),
    );
  }
}

class _ProfileWrapper extends StatelessWidget {
  const _ProfileWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated && !state.isGuest) {
          final user = state.user;
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.profile),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: user?.photoUrl != null
                        ? CachedNetworkImageProvider(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user?.displayName ?? 'No Name',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Center(
                  child: Text(
                    user?.phoneNumber ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Text(
                    AppLocalizations.of(context)!.settings,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)!.language),
                  subtitle: Text(Localizations.localeOf(context).languageCode.toUpperCase()),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _showLanguageDialog(context),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Text(
                    'Spread the Word',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined, color: Colors.blue),
                  title: const Text('Invite Friends'),
                  subtitle: const Text('Invite your friends to use Business Diary'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _shareApp(
                    message: "Hey! Check out Business Diary - A global business directory with real-time promos. Download it now to find local deals! https://play.google.com/store/apps/details?id=com.help.businessdiary",
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: Colors.blue),
                  title: const Text('Share App'),
                  subtitle: const Text('Share this app with others'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _shareApp(
                    message: "Business Diary - The ultimate platform for local business discovery and real-time promos. Get it here: https://play.google.com/store/apps/details?id=com.help.businessdiary",
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Text(
                    'Policies',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blue),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                  onTap: () => _launchURL('https://mvapptools.blogspot.com/2026/03/privacy-policy.html'),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Colors.blue),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                  onTap: () => _launchURL('https://mvapptools.blogspot.com/2026/03/terms-conditions.html'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.blue),
                  title: const Text('Data Deletion Policy'),
                  trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                  onTap: () => _launchURL('https://mvapptools.blogspot.com/2026/03/data-deletion-policy.html'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Permanently delete your account and data', style: TextStyle(fontSize: 12)),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.logout),
                  onTap: () {
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                  },
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocalizations.supportedLocales.map((locale) {
            String languageName = '';
            switch (locale.languageCode) {
              case 'en':
                languageName = 'English';
                break;
              case 'hi':
                languageName = 'हिन्दी';
                break;
              case 'es':
                languageName = 'Español';
                break;
              case 'zh':
                languageName = '中文 (Chinese)';
                break;
              case 'de':
                languageName = 'Deutsch (German)';
                break;
              case 'it':
                languageName = 'Italiano (Italian)';
                break;
              case 'ur':
                languageName = 'اردو (Urdu)';
                break;
              case 'ar':
                languageName = 'العربية (Arabic)';
                break;
              default:
                languageName = locale.languageCode.toUpperCase();
            }

            return ListTile(
              title: Text(languageName),
              onTap: () {
                context.read<LocaleCubit>().setLocale(locale);
                Navigator.pop(dialogContext);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is permanent and cannot be undone. All your profile data, favorites, and uploaded images will be permanently deleted from our servers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthAccountDeletionRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _shareApp({required String message}) {
    Share.share(message);
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                // Show button if no user data exists (Guest, Unauthenticated, or Initial)
                if (state.user == null || 
                    state.isGuest ||
                    state.status == AuthStatus.unauthenticated || 
                    state.status == AuthStatus.initial) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Login / Sign Up'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
