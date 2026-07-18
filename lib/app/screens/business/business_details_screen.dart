import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/models/business_model.dart';
import '../../../common/models/promo_model.dart';
import '../../../common/models/offer_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/promo/promo_bloc.dart';
import '../../bloc/promo/promo_event.dart';
import '../../bloc/promo/promo_state.dart';
import '../../bloc/review/review_bloc.dart';
import '../../bloc/review/review_event.dart';
import '../../bloc/review/review_state.dart';
import '../../../../common/models/review_model.dart';
import 'widgets/add_review_dialog.dart';
import 'widgets/reply_review_dialog.dart';
import 'full_screen_image_viewer.dart';

class BusinessDetailsScreen extends StatefulWidget {
  final Business business;

  const BusinessDetailsScreen({super.key, required this.business});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isReviewsExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<PromoBloc>().add(PromoLoadForBusinessRequested(widget.business.id));
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<PromoBloc>().add(UserClaimsLoadRequested(user.uid));
    }
    context.read<ReviewBloc>().add(ReviewFetchRequested(widget.business.id));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  void _openMaps() {
    if (widget.business.latitude != null && widget.business.longitude != null) {
      _launchUrl('https://www.google.com/maps/search/?api=1&query=${widget.business.latitude},${widget.business.longitude}');
    } else {
      _launchUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.business.location)}');
    }
  }

  void _openFullScreenImage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imageUrls: widget.business.imageUrls,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PromoBloc, PromoState>(
      listenWhen: (previous, current) => !previous.claimSuccess && current.claimSuccess,
      listener: (context, state) {
        if (state.claimSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promo claimed successfully! View it in the Offers tab.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: BlocListener<PromoBloc, PromoState>(
        listenWhen: (previous, current) => 
            previous.status == PromoStatus.claiming && current.status == PromoStatus.failure,
        listener: (context, state) {
          if (state.status == PromoStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'Action failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickActions(),
                      const SizedBox(height: 32),
                      _buildPromosAndOffers(),
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, 'About the Business'),
                      const SizedBox(height: 12),
                      Text(
                        widget.business.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, 'Contact Information'),
                      const SizedBox(height: 16),
                      _buildContactTile(
                        context,
                        icon: Icons.phone_rounded,
                        title: 'Phone',
                        subtitle: widget.business.phoneNumber,
                        onTap: () => _launchUrl('tel:${widget.business.phoneNumber}'),
                      ),
                      _buildContactTile(
                        context,
                        icon: Icons.chat_rounded,
                        title: 'WhatsApp',
                        subtitle: widget.business.whatsappNumber,
                        onTap: () => _launchUrl('https://wa.me/${widget.business.whatsappNumber.replaceAll('+', '')}'),
                        color: Colors.green,
                      ),
                      _buildContactTile(
                        context,
                        icon: Icons.email_rounded,
                        title: 'Email',
                        subtitle: widget.business.email,
                        onTap: () => _launchUrl('mailto:${widget.business.email}'),
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 32),
                      _buildReviewsSection(),
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, 'Location'),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        color: Colors.grey[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.location_on_rounded, color: Theme.of(context).primaryColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.business.location,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${widget.business.city}, ${widget.business.country} - ${widget.business.zipcode}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openMaps,
                          icon: const Icon(Icons.directions_rounded),
                          label: const Text('Get Directions'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.business.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
        background: GestureDetector(
          onTap: () {
            if (widget.business.imageUrls.isNotEmpty) {
              _openFullScreenImage(_currentPage);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.business.imageUrls.isNotEmpty
                  ? PageView.builder(
                      controller: _pageController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: widget.business.imageUrls.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: widget.business.imageUrls[index],
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Container(
                      color: Theme.of(context).primaryColor,
                      child: const Icon(Icons.business, size: 100, color: Colors.white54),
                    ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
              ),
              if (widget.business.imageUrls.length > 1)
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.business.imageUrls.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () {},
        ),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isFavorite = state.user?.favorites.contains(widget.business.id) ?? false;
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: () {
                if (state.user == null || state.isGuest) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login to favorite businesses')),
                  );
                  return;
                }
                context.read<AuthBloc>().add(AuthToggleFavoriteRequested(widget.business.id));
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(Icons.call_rounded, 'Call', Colors.blue, () => _launchUrl('tel:${widget.business.phoneNumber}')),
        _buildActionButton(Icons.chat_rounded, 'WhatsApp', Colors.green, () => _launchUrl('https://wa.me/${widget.business.whatsappNumber.replaceAll('+', '')}')),
        _buildActionButton(Icons.directions_rounded, 'Map', Colors.orange, _openMaps),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPromosAndOffers() {
    return BlocBuilder<PromoBloc, PromoState>(
      builder: (context, state) {
        final claimedPromoIds = state.userClaims.map((c) => c['promoId']).toSet();
        final activePromos = state.promos.where((p) => p.isAvailable && !claimedPromoIds.contains(p.id)).toList();
        final activeOffers = state.offers.where((o) => o.isAvailable).toList();

        if (activePromos.isEmpty && activeOffers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Promos & Offers'),
            const SizedBox(height: 16),
            if (activeOffers.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeOffers.length,
                  itemBuilder: (context, index) {
                    final offer = activeOffers[index];
                    return _buildOfferCard(offer);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (activePromos.isNotEmpty) ...[
              ...activePromos.map((promo) => _buildPromoCard(promo)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOfferCard(Offer offer) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offer.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _SmallImageCarousel(imageUrls: offer.imageUrls, height: 100),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(offer.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(offer.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${offer.startDate != null ? DateFormat('MMM dd').format(offer.startDate!) : 'N/A'} - ${offer.endDate != null ? DateFormat('MMM dd, yyyy').format(offer.endDate!) : 'N/A'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(PromoCode promo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.withValues(alpha: 0.3))),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: Colors.blue.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (promo.imageUrls.isNotEmpty)
            _SmallImageCarousel(imageUrls: promo.imageUrls, height: 150),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                      child: Text(promo.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Text('Remaining: ${promo.remainingUsage}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(promo.description, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'Valid: ${promo.startDate != null ? DateFormat('MMM dd').format(promo.startDate!) : 'N/A'} - ${promo.endDate != null ? DateFormat('MMM dd, yyyy').format(promo.endDate!) : 'N/A'}',
                      style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (promo.termsAndConditions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('* ${promo.termsAndConditions}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
                const SizedBox(height: 16),
                BlocBuilder<PromoBloc, PromoState>(
                  builder: (context, promoState) {
                    return BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final isClaimingThis = promoState.status == PromoStatus.claiming && 
                                              promoState.claimingPromoId == promo.id;

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isClaimingThis
                                ? null
                                : () {
                                    if (authState.user == null || authState.isGuest) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to claim promo codes')));
                                      return;
                                    }
                                    context.read<PromoBloc>().add(
                                          PromoClaimRequested(
                                            authState.user!.uid,
                                            promo.id,
                                            userName: authState.user!.displayName,
                                            userPhone: authState.user!.phoneNumber,
                                          ),
                                        );
                                  },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            child: isClaimingThis
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Claim Now'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return BlocBuilder<ReviewBloc, ReviewState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(context, 'Reviews (${state.reviews.length})'),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final isOwner = authState.user?.uid == widget.business.ownerId;
                    if (isOwner || authState.isGuest) return const SizedBox.shrink();
                    
                    // Check if user already reviewed
                    final hasReviewed = state.reviews.any((r) => r.userId == authState.user?.uid);
                    if (hasReviewed) return const SizedBox.shrink();

                    return TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddReviewDialog(business: widget.business),
                        );
                      },
                      icon: const Icon(Icons.add_comment),
                      label: const Text('Add Review'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.status == ReviewStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (state.reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No reviews yet. Be the first to review!')),
              )
            else
              Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _isReviewsExpanded
                        ? state.reviews.length
                        : (state.reviews.length > 2 ? 2 : state.reviews.length),
                    itemBuilder: (context, index) {
                      final review = state.reviews[index];
                      return _buildReviewTile(review);
                    },
                  ),
                  if (state.reviews.length > 2)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isReviewsExpanded = !_isReviewsExpanded;
                          });
                        },
                        icon: Icon(
                          _isReviewsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                        ),
                        label: Text(_isReviewsExpanded ? 'View Less' : 'View All'),
                      ),
                    ),
                ],
              ),
          ],
        );
      }
    );
  }

  Widget _buildReviewTile(Review review) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isOwner = authState.user?.uid == widget.business.ownerId;
        final isMyReview = authState.user?.uid == review.userId;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: review.userPhotoUrl != null
                          ? CachedNetworkImageProvider(review.userPhotoUrl!)
                          : null,
                      child: review.userPhotoUrl == null ? const Icon(Icons.person, size: 20) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            DateFormat('MMM dd, yyyy').format(review.createdAt),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (isMyReview) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddReviewDialog(
                              business: widget.business,
                              existingReview: review,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Review'),
                              content: const Text('Are you sure you want to delete your review?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<ReviewBloc>().add(ReviewDeleteRequested(review));
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(review.comment),
                if (review.ownerReply != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Owner\'s Reply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            if (review.ownerReplyAt != null)
                              Text(
                                DateFormat('MMM dd, yyyy').format(review.ownerReplyAt!),
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(review.ownerReply!, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                if (isOwner) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ReplyReviewDialog(review: review),
                        );
                      },
                      icon: const Icon(Icons.reply, size: 18),
                      label: Text(review.ownerReply == null ? 'Reply' : 'Edit Reply'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }
}

class _SmallImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const _SmallImageCarousel({required this.imageUrls, required this.height});

  @override
  State<_SmallImageCarousel> createState() => _SmallImageCarouselState();
}

class _SmallImageCarouselState extends State<_SmallImageCarousel> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(
                  imageUrls: widget.imageUrls,
                  initialIndex: _currentPage,
                ),
              ),
            );
          },
          child: SizedBox(
            height: widget.height,
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                height: widget.height,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
