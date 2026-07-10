import 'package:flutter/material.dart';
import '../models/business_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/bloc/auth/auth_bloc.dart';
import '../../app/bloc/auth/auth_state.dart';
import '../../app/bloc/auth/auth_event.dart';

class BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const BusinessCard({
    super.key,
    required this.business,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: business.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: business.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.business, size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.business, size: 50, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          business.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (business.isVerified)
                        const Icon(Icons.verified, color: Colors.blue, size: 20),
                      const Spacer(),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isFavorite = state.user?.favorites.contains(business.id) ?? false;
                          return IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              if (state.user == null || state.isGuest) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please login to favorite businesses')),
                                );
                                return;
                              }
                              context.read<AuthBloc>().add(AuthToggleFavoriteRequested(business.id));
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.category,
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${business.city}, ${business.country}',
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        business.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(' (${business.totalReviews} reviews)'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.directions, color: Colors.blue),
                        onPressed: () {
                          // TODO: Implement navigation logic using business.latitude and business.longitude
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
