import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/business/business_bloc.dart';
import '../bloc/business/business_state.dart' as bloc_state;
import '../../common/widgets/business_card.dart';
import 'business/business_details_screen.dart';
import 'auth/login_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState.user == null || authState.isGuest) {
            return _buildLoginPrompt(context);
          }

          final favoriteIds = authState.user!.favorites;

          if (favoriteIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Businesses you favorite will appear here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return BlocBuilder<BusinessBloc, bloc_state.BusinessState>(
            builder: (context, businessState) {
              if (businessState.status == bloc_state.BusinessBlocStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final favoriteBusinesses = businessState.businesses
                  .where((b) => favoriteIds.contains(b.id))
                  .toList();

              if (favoriteBusinesses.isEmpty && businessState.status == bloc_state.BusinessBlocStatus.success) {
                // This might happen if businesses aren't loaded yet or IDs are invalid
                return const Center(child: Text('Loading your favorites...'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favoriteBusinesses.length,
                itemBuilder: (context, index) {
                  final business = favoriteBusinesses[index];
                  return BusinessCard(
                    business: business,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessDetailsScreen(business: business),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sign in to see your favorite shops!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Login / Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
