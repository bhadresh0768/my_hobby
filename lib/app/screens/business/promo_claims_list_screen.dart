import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../common/models/promo_model.dart';
import '../../bloc/promo/promo_bloc.dart';
import '../../bloc/promo/promo_event.dart';
import '../../bloc/promo/promo_state.dart';

class PromoClaimsListScreen extends StatefulWidget {
  final PromoCode promo;

  const PromoClaimsListScreen({super.key, required this.promo});

  @override
  State<PromoClaimsListScreen> createState() => _PromoClaimsListScreenState();
}

class _PromoClaimsListScreenState extends State<PromoClaimsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PromoBloc>().add(PromoClaimsLoadRequested(widget.promo.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Claims: ${widget.promo.code}')),
      body: BlocBuilder<PromoBloc, PromoState>(
        builder: (context, state) {
          if (state.status == PromoStatus.loading && state.promoClaims.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.promoClaims.isEmpty) {
            return const Center(child: Text('No claims yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.promoClaims.length,
            itemBuilder: (context, index) {
              final claim = state.promoClaims[index];
              final date = claim['claimedAt'] != null ? (claim['claimedAt'] as dynamic).toDate() : DateTime.now();
              final status = claim['status'] ?? 'applied';
              final isRedeemed = status == 'redeemed';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRedeemed ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: isRedeemed ? Colors.green : Colors.blue,
                      ),
                    ),
                    title: Text(
                      claim['userName'] ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone: ${claim['userPhone'] ?? 'N/A'}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified_user, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            const Text('Code: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              claim['verificationCode'] ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Claimed: ${DateFormat('MMM dd, HH:mm').format(date)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: isRedeemed
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Redeemed',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () => _showVerifyDialog(context, claim),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text('Redeem'),
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showVerifyDialog(BuildContext context, Map<String, dynamic> claim) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Promo Claim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 10-digit Verification Code shown on the customer\'s screen:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                hintText: '10-digit Code',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.length == 10) {
                context.read<PromoBloc>().add(
                      PromoRedeemRequested(claim['userId'], widget.promo.id, codeController.text),
                    );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 10-digit code')),
                );
              }
            },
            child: const Text('Verify & Redeem'),
          ),
        ],
      ),
    );
  }
}
