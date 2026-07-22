import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../bloc/business/business_state.dart' as bloc_state;
import 'business/business_registration_screen.dart';
import 'business/business_details_screen.dart';
import '../../common/utils/location_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  String _selectedSortBy = 'newest';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final businessBloc = context.read<BusinessBloc>();
    
    // 1. Get current location and city
    final position = await LocationHelper.getCurrentLocation(context);
    String? detectedCity;
    
    if (position != null) {
      detectedCity = await LocationHelper.getCityFromCoordinates(position.latitude, position.longitude);
    }

    // 2. Fetch businesses for the detected city (or global if not found)
    if (context.mounted) {
      businessBloc.add(BusinessFetchRequested(
        city: detectedCity,
        sortBy: 'newest',
      ));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<BusinessBloc>().state;
      context.read<BusinessBloc>().add(BusinessLoadMoreRequested(
        category: _selectedCategory,
        city: state.selectedCity,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: BlocBuilder<BusinessBloc, bloc_state.BusinessState>(
          builder: (context, state) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 4),
                Text(
                  state.selectedCity ?? 'Detecting...',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _showSortBottomSheet(context),
            tooltip: 'Sort & Filter',
          ),
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
                  return BlocBuilder<BusinessBloc, bloc_state.BusinessState>(
                    builder: (context, state) {
                      if (state.status == bloc_state.BusinessBlocStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      // Filter out businesses owned by the current user
                      final filteredBusinesses = state.businesses
                          .where((business) => business.ownerId != currentUserId)
                          .toList();

                      if (filteredBusinesses.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.business_center_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No businesses found in your area.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try registering the first business here!',
                                style: TextStyle(color: Colors.grey),
                              ),
                              if (state.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Error: ${state.errorMessage}',
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.selectedCity != null && 
                              filteredBusinesses.isNotEmpty && 
                              filteredBusinesses.first.city.toLowerCase() != state.selectedCity!.toLowerCase())
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'No businesses in your city yet. Showing Top Rated businesses globally:',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: _isGridView
                                ? _buildBusinessGrid(filteredBusinesses, state)
                                : _buildBusinessList(filteredBusinesses, state),
                          ),
                        ],
                      );
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
                context.read<BusinessBloc>().add(BusinessFetchRequested(
                  category: category,
                  sortBy: _selectedSortBy,
                  latitude: context.read<BusinessBloc>().state.latitude,
                  longitude: context.read<BusinessBloc>().state.longitude,
                ));
              },
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessList(List<Business> businesses, bloc_state.BusinessState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<BusinessBloc>().add(BusinessFetchRequested(
          category: _selectedCategory,
          sortBy: _selectedSortBy,
          latitude: state.latitude,
          longitude: state.longitude,
        ));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: businesses.length + (state.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < businesses.length) {
            return BusinessCard(
              business: businesses[index],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BusinessDetailsScreen(business: businesses[index]),
                  ),
                );
              },
            );
          } else {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }

  Widget _buildBusinessGrid(List<Business> businesses, bloc_state.BusinessState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<BusinessBloc>().add(BusinessFetchRequested(category: _selectedCategory));
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: businesses.length + (state.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < businesses.length) {
            return BusinessCard(
              business: businesses[index],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BusinessDetailsScreen(business: businesses[index]),
                  ),
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sort By',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSortOption(
                    context,
                    setModalState,
                    title: 'Newest First',
                    icon: Icons.new_releases_outlined,
                    value: 'newest',
                  ),
                  _buildSortOption(
                    context,
                    setModalState,
                    title: 'Top Rated',
                    icon: Icons.star_outline_rounded,
                    value: 'top_rated',
                  ),
                  _buildSortOption(
                    context,
                    setModalState,
                    title: 'Nearby (50km)',
                    icon: Icons.near_me_outlined,
                    value: 'nearby',
                  ),
                  _buildSortOption(
                    context,
                    setModalState,
                    title: 'Alphabetical',
                    icon: Icons.sort_by_alpha_outlined,
                    value: 'name',
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    StateSetter setModalState, {
    required String title,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedSortBy == value;
    final primaryColor = Theme.of(context).primaryColor;

    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? primaryColor : Colors.black87,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle, color: primaryColor) : null,
      onTap: () async {
        if (value == 'nearby') {
          final position = await LocationHelper.getCurrentLocation(context);
          if (position != null && context.mounted) {
            setState(() {
              _selectedSortBy = value;
            });
            context.read<BusinessBloc>().add(BusinessFetchRequested(
              category: _selectedCategory,
              sortBy: value,
              latitude: position.latitude,
              longitude: position.longitude,
            ));
            Navigator.pop(context);
          }
        } else {
          setState(() {
            _selectedSortBy = value;
          });
          context.read<BusinessBloc>().add(BusinessFetchRequested(
            category: _selectedCategory,
            sortBy: value,
          ));
          Navigator.pop(context);
        }
      },
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
