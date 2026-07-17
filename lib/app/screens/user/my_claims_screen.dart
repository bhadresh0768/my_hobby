import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../common/models/promo_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/promo/promo_bloc.dart';
import '../../bloc/promo/promo_event.dart';
import '../../bloc/promo/promo_state.dart';
import '../business/business_details_screen.dart';
import '../business/full_screen_image_viewer.dart';
import '../../../core/repositories/business_repository.dart';

class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'Applied', 'Redeemed'];

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  void _loadClaims() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<PromoBloc>().add(UserClaimsLoadRequested(user.uid, status: _selectedStatus));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) => 
              previous.status != AuthStatus.authenticated && current.status == AuthStatus.authenticated,
          listener: (context, state) {
            _loadClaims();
          },
        ),
        BlocListener<PromoBloc, PromoState>(
          listenWhen: (previous, current) => !previous.cancelSuccess && current.cancelSuccess,
          listener: (context, state) {
            if (state.cancelSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Claim canceled successfully. The spot is now available for others.'),
                  backgroundColor: Colors.blue,
                ),
              );
            }
          },
        ),
        BlocListener<PromoBloc, PromoState>(
          listenWhen: (previous, current) => 
              previous.status != PromoStatus.failure && current.status == PromoStatus.failure,
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
        ),
      ],
      child: Scaffold(
          appBar: AppBar(title: const Text('My Claimed Promos')),
          body: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: BlocBuilder<PromoBloc, PromoState>(
                  builder: (context, state) {
                    if (state.status == PromoStatus.loading && state.userClaims.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.userClaims.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _selectedStatus == 'All' 
                                    ? 'No claimed promos yet.' 
                                    : 'No $_selectedStatus promos found.',
                                textAlign: TextAlign.center,
                              ),
                              if (state.error != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Error: ${state.error}',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.userClaims.length,
                      itemBuilder: (context, index) {
                        final claim = state.userClaims[index];
                        final PromoCode promo = claim['promo'];
                        final status = claim['status'] ?? 'applied';
                        final date = claim['claimedAt'] != null ? (claim['claimedAt'] as dynamic).toDate() : DateTime.now();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (promo.imageUrls.isNotEmpty)
                                _PromoImageCarousel(imageUrls: promo.imageUrls),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                                          child: Text(promo.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                        _buildStatusBadge(status, promo.isExpired),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(promo.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDiscount(promo),
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.info_outline, color: Colors.grey),
                                          onPressed: () => _showTermsDialog(context, promo.termsAndConditions),
                                          tooltip: 'Terms and Conditions',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (status == 'applied')
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.verified_user, color: Colors.blue, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Verification Code: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                            Text(
                                              claim['verificationCode'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.copy, color: Colors.blue, size: 20),
                                              onPressed: () {
                                                final code = claim['verificationCode'] ?? '';
                                                if (code.isNotEmpty) {
                                                  Clipboard.setData(ClipboardData(text: code));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Verification code copied to clipboard')),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Text('Claimed on: ${DateFormat('MMM dd, yyyy').format(date)}', style: TextStyle(color: Colors.grey[600])),
                                    if (promo.endDate != null)
                                      Text('Valid until: ${DateFormat('MMM dd, yyyy').format(promo.endDate!)}',
                                          style: TextStyle(color: promo.isExpired ? Colors.red : Colors.grey[600])),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (status == 'applied' && !promo.isExpired)
                                          TextButton.icon(
                                            onPressed: () => _confirmCancel(context, promo.id),
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            label: const Text('Cancel Claim', style: TextStyle(color: Colors.red)),
                                          ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final businessId = claim['businessId'];
                                            if (businessId != null) {
                                              final business = await context.read<BusinessRepository>().getBusiness(businessId);
                                              if (business != null && context.mounted) {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => BusinessDetailsScreen(business: business),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('View Business'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
  }

  String _formatDiscount(PromoCode promo) {
    if (promo.discountType == 'percentage') {
      return '${promo.discountValue.toStringAsFixed(0)}% OFF';
    } else {
      final formatter = NumberFormat.simpleCurrency(decimalDigits: 0);
      return '${formatter.format(promo.discountValue)} OFF';
    }
  }

  void _showTermsDialog(BuildContext context, String terms) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text(terms.isEmpty ? 'No specific terms and conditions provided.' : terms),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _statuses.map((status) {
            final isSelected = _selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(status),
                selected: isSelected,
                checkmarkColor: Colors.white,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                    _loadClaims();
                  }
                },
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isExpired) {
    Color color = Colors.blue;
    String text = 'Applied';

    if (status == 'redeemed') {
      color = Colors.green;
      text = 'Redeemed';
    } else if (isExpired) {
      color = Colors.grey;
      text = 'Expired';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmCancel(BuildContext context, String promoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Claim'),
        content: const Text('Are you sure you want to cancel this claim? This will free up the spot for another user.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          TextButton(
            onPressed: () {
              final user = context.read<AuthBloc>().state.user;
              if (user != null) {
                context.read<PromoBloc>().add(PromoCancelRequested(user.uid, promoId));
              }
              Navigator.pop(context);
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PromoImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const _PromoImageCarousel({required this.imageUrls});

  @override
  State<_PromoImageCarousel> createState() => _PromoImageCarouselState();
}

class _PromoImageCarouselState extends State<_PromoImageCarousel> {
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
            height: 150,
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => Image.network(
                widget.imageUrls[index],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error)),
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
