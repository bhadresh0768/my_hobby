import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../common/models/business_model.dart';
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
    return Scaffold(
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
        IconButton(
          icon: const Icon(Icons.favorite_border_rounded),
          onPressed: () {},
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
