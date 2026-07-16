import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/models/business_model.dart';
import '../../../common/models/promo_model.dart';
import '../../../common/models/offer_model.dart';
import '../../bloc/promo/promo_bloc.dart';
import '../../bloc/promo/promo_event.dart';
import '../../bloc/promo/promo_state.dart';
import 'add_edit_promo_screen.dart';
import 'add_edit_offer_screen.dart';
import 'promo_claims_list_screen.dart';

class ManagePromosOffersScreen extends StatefulWidget {
  final Business business;

  const ManagePromosOffersScreen({super.key, required this.business});

  @override
  State<ManagePromosOffersScreen> createState() => _ManagePromosOffersScreenState();
}

class _ManagePromosOffersScreenState extends State<ManagePromosOffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<PromoBloc>().add(PromoLoadForBusinessRequested(widget.business.id));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage: ${widget.business.name}'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Promo Codes', icon: Icon(Icons.confirmation_number)),
            Tab(text: 'General Offers', icon: Icon(Icons.local_offer)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPromosTab(),
          _buildOffersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddEditPromoScreen(businessId: widget.business.id)),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddEditOfferScreen(businessId: widget.business.id)),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPromosTab() {
    return BlocBuilder<PromoBloc, PromoState>(
      builder: (context, state) {
        if (state.status == PromoStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.promos.isEmpty) {
          return const Center(child: Text('No promo codes yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.promos.length,
          itemBuilder: (context, index) {
            final promoItem = state.promos[index];
            return Card(
              child: ListTile(
                title: Text(promoItem.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(promoItem.description),
                    const SizedBox(height: 4),
                    Text('Remaining: ${promoItem.remainingUsage} / ${promoItem.maxUsage}',
                        style: TextStyle(color: promoItem.remainingUsage > 0 ? Colors.green : Colors.red)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: promoItem.isActive,
                      onChanged: (val) {
                        final updated = PromoCode(
                          id: promoItem.id,
                          businessId: promoItem.businessId,
                          code: promoItem.code,
                          description: promoItem.description,
                          discountValue: promoItem.discountValue,
                          discountType: promoItem.discountType,
                          maxUsage: promoItem.maxUsage,
                          currentUsage: promoItem.currentUsage,
                          startDate: promoItem.startDate,
                          endDate: promoItem.endDate,
                          imageUrls: promoItem.imageUrls,
                          termsAndConditions: promoItem.termsAndConditions,
                          isActive: val,
                        );
                        context.read<PromoBloc>().add(PromoUpdateRequested(updated));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.people, color: Colors.green),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => PromoClaimsListScreen(promo: promoItem)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AddEditPromoScreen(businessId: widget.business.id, promo: promoItem)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => context.read<PromoBloc>().add(PromoDeleteRequested(promoItem.id)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOffersTab() {
    return BlocBuilder<PromoBloc, PromoState>(
      builder: (context, state) {
        if (state.status == PromoStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.offers.isEmpty) {
          return const Center(child: Text('No offers yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.offers.length,
          itemBuilder: (context, index) {
            final offer = state.offers[index];
            return Card(
              child: ListTile(
                title: Text(offer.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(offer.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: offer.isActive,
                      onChanged: (val) {
                        final updated = Offer(
                          id: offer.id,
                          businessId: offer.businessId,
                          title: offer.title,
                          description: offer.description,
                          startDate: offer.startDate,
                          endDate: offer.endDate,
                          imageUrls: offer.imageUrls,
                          termsAndConditions: offer.termsAndConditions,
                          isActive: val,
                        );
                        context.read<PromoBloc>().add(OfferUpdateRequested(updated));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AddEditOfferScreen(businessId: widget.business.id, offer: offer)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => context.read<PromoBloc>().add(OfferDeleteRequested(offer.id)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
