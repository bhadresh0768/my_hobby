import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../common/widgets/business_card.dart';
import '../../common/models/business_model.dart';
import '../../core/app_constants.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/business/business_bloc.dart';
import '../bloc/business/business_event.dart';
import '../bloc/business/business_state.dart';
import 'business/business_registration_screen.dart';
import 'business/business_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    context.read<BusinessBloc>().add(BusinessFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          // IconButton(
          //   icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          //   onPressed: () {
          //     setState(() {
          //       _isGridView = !_isGridView;
          //     });
          //   },
          // ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              // Show logout only if fully authenticated (not guest)
              if (state.status == AuthStatus.authenticated && !state.isGuest) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _showLogoutDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged out successfully')),
            );
          }
        },
        child: Column(
          children: [
            _buildSearchBar(l10n),
            _buildCategoryFilters(),
            Expanded(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final currentUserId = authState.user?.uid;
                  return BlocBuilder<BusinessBloc, BusinessState>(
                    builder: (context, state) {
                      if (state.status == BusinessStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      // Filter out businesses owned by the current user
                      final filteredBusinesses = state.businesses
                          .where((business) => business.ownerId != currentUserId)
                          .toList();

                      if (filteredBusinesses.isEmpty) {
                        return const Center(child: Text('No businesses found.'));
                      }
                      return _isGridView
                          ? _buildBusinessGrid(filteredBusinesses)
                          : _buildBusinessList(filteredBusinesses);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BusinessRegistrationScreen()),
          );
        },
        label: Text(l10n.registerBusiness),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = ['All', ...AppConstants.businessCategories];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
                context.read<BusinessBloc>().add(BusinessFetchRequested(category: category));
              },
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessList(List<Business> businesses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: businesses.length,
      itemBuilder: (context, index) => BusinessCard(
        business: businesses[index],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BusinessDetailsScreen(business: businesses[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessGrid(List<Business> businesses) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: businesses.length,
      itemBuilder: (context, index) => BusinessCard(
        business: businesses[index],
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BusinessDetailsScreen(business: businesses[index]),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to logout? You will need to verify your number again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(AuthSignOutRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
