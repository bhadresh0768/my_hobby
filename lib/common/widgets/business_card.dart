import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/business_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/bloc/auth/auth_bloc.dart';
import '../../app/bloc/auth/auth_state.dart';
import '../../app/bloc/auth/auth_event.dart';
import '../../app/bloc/promo/promo_bloc.dart';
import '../../app/bloc/promo/promo_state.dart';
import '../../app/bloc/promo/promo_event.dart';
import '../../core/repositories/promo_repository.dart';

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
            Stack(
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
                // Offer Indicator
                Positioned(
                  top: 12,
                  left: 12,
                  child: StreamBuilder(
                    stream: context.read<PromoRepository>().getPromosForBusiness(business.id),
                    builder: (context, promoSnapshot) {
                      return StreamBuilder(
                        stream: context.read<PromoRepository>().getOffersForBusiness(business.id),
                        builder: (context, offerSnapshot) {
                          final hasPromos = promoSnapshot.hasData && promoSnapshot.data!.any((p) => p.isAvailable);
                          final hasOffers = offerSnapshot.hasData && offerSnapshot.data!.any((o) => o.isAvailable);

                          if (hasPromos || hasOffers) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_offer, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'DEAL ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              business.category,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (business.isVerified)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.verified, color: Colors.blue, size: 20),
                        ),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isFavorite = state.user?.favorites.contains(business.id) ?? false;
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(Icons.location_on, size: 16, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business.location,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            Text(
                              '${business.city}, ${business.state}, ${business.country} - ${business.zipcode}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        business.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' (${business.totalReviews} reviews)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (business.latitude != null && business.longitude != null) {
                            final url =
                                'https://www.google.com/maps/search/?api=1&query=${business.latitude},${business.longitude}';
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open maps')),
                                );
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No location coordinates available')),
                            );
                          }
                        },
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
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
