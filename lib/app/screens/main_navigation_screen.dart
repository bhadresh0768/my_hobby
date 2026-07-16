import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/auth/auth_event.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'auth/login_screen.dart';
import 'auth/edit_profile_screen.dart';
import 'business/my_businesses_screen.dart';
import 'user/my_claims_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  List<Widget> get _widgetOptions => <Widget>[
    const HomeScreen(),
    const FavoritesScreen(),
    const MyClaimsScreen(),
    const _ProfileWrapper(),
  ];

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
        // We stay on the LoginScreen (which will push OTP screen) during the whole flow.
        final bool isAuthenticating = state.status == AuthStatus.codeSent || 
                                     state.status == AuthStatus.loading ||
                                     state.status == AuthStatus.error;

        if (!state.isGuest && state.user == null && 
            (state.status == AuthStatus.unauthenticated || isAuthenticating)) {
          return const LoginScreen();
        }

        // 3. Main App UI (Authenticated or Guest)
        return Scaffold(
          body: Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                activeIcon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_offer_outlined),
                activeIcon: Icon(Icons.local_offer),
                label: 'Offers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
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
              title: const Text('Profile'),
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
                ListTile(
                  leading: const Icon(Icons.business_rounded, color: Colors.blue),
                  title: const Text('My Businesses'),
                  subtitle: const Text('Manage your registered businesses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyBusinessesScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
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
