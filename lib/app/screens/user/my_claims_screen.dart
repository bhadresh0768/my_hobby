import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../common/models/promo_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/promo/promo_bloc.dart';
import '../../bloc/promo/promo_event.dart';
import '../../bloc/promo/promo_state.dart';
import '../business/business_details_screen.dart';
import '../../../core/repositories/business_repository.dart';

class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      context.read<PromoBloc>().add(UserClaimsLoadRequested(user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PromoBloc, PromoState>(
      listenWhen: (previous, current) => current.cancelSuccess,
      listener: (context, state) {
        if (state.cancelSuccess) {
          // Success after cancellation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Claim canceled successfully. The spot is now available for others.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      },
      child: BlocListener<PromoBloc, PromoState>(
        listenWhen: (previous, current) => 
            previous.status == PromoStatus.canceling && current.status == PromoStatus.failure,
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
        appBar: AppBar(title: const Text('My Claimed Promos')),
        body: BlocBuilder<PromoBloc, PromoState>(
          builder: (context, state) {
            if (state.status == PromoStatus.loading && state.userClaims.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.userClaims.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No claimed promos yet.'),
                  ],
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
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
                        Text(promo.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                );
              },
            );
          },
        ),
      ),
    ));
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
