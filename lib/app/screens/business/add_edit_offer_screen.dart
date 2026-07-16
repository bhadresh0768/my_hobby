import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../common/models/offer_model.dart';
import '../../bloc/promo/promo_bloc.dart';
import '../../bloc/promo/promo_event.dart';
import '../../bloc/promo/promo_state.dart';

class AddEditOfferScreen extends StatefulWidget {
  final String businessId;
  final Offer? offer;

  const AddEditOfferScreen({super.key, required this.businessId, this.offer});

  @override
  State<AddEditOfferScreen> createState() => _AddEditOfferScreenState();
}

class _AddEditOfferScreenState extends State<AddEditOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _termsController;
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.offer?.title ?? '');
    _descriptionController = TextEditingController(text: widget.offer?.description ?? '');
    _termsController = TextEditingController(text: widget.offer?.termsAndConditions ?? '');
    _startDate = widget.offer?.startDate;
    _endDate = widget.offer?.endDate;
    _isActive = widget.offer?.isActive ?? true;
    _existingImageUrls = widget.offer?.imageUrls ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_newImages.length + _existingImageUrls.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 3 images allowed')));
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final compressedFile = await _compressImage(File(pickedFile.path));
      if (compressedFile != null) {
        setState(() {
          _newImages.add(compressedFile);
        });
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    final targetPath = "$path/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 1024,
      minHeight: 1024,
    );

    return result != null ? File(result.path) : null;
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both Start and End dates')),
        );
        return;
      }

      final offer = Offer(
        id: widget.offer?.id ?? const Uuid().v4(),
        businessId: widget.businessId,
        title: _titleController.text,
        description: _descriptionController.text,
        startDate: _startDate,
        endDate: _endDate,
        imageUrls: _existingImageUrls,
        termsAndConditions: _termsController.text,
        isActive: _isActive,
      );

      if (widget.offer == null) {
        context.read<PromoBloc>().add(OfferCreateRequested(offer, images: _newImages));
      } else {
        context.read<PromoBloc>().add(OfferUpdateRequested(offer, newImages: _newImages));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.offer == null ? 'Add General Offer' : 'Edit Offer')),
      body: BlocListener<PromoBloc, PromoState>(
        listener: (context, state) {
          if (state.status == PromoStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error ?? 'Error')));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Offer Title (e.g. Buy 1 Get 1)', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Enter title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                  validator: (val) => val!.isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 16),
                _buildDatePickers(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _termsController,
                  decoration: const InputDecoration(labelText: 'Terms & Conditions', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Active'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                const SizedBox(height: 16),
                const Text('Images (Max 3)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildImagePicker(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(widget.offer == null ? 'Create Offer' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickers() {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: const Text('Start Date *', style: TextStyle(fontSize: 14)),
            subtitle: Text(_startDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_startDate!)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event, color: Colors.redAccent),
            title: const Text('End Date *', style: TextStyle(fontSize: 14)),
            subtitle: Text(_endDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_endDate!)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _endDate = picked);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: [
            ..._existingImageUrls.map((url) => Stack(
                  children: [
                    Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          context.read<PromoBloc>().add(PromoImageDeleteRequested(url));
                          setState(() => _existingImageUrls.remove(url));
                        },
                        child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                      ),
                    ),
                  ],
                )),
            ..._newImages.map((file) => Stack(
                  children: [
                    Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _newImages.remove(file)),
                        child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                      ),
                    ),
                  ],
                )),
            if (_newImages.length + _existingImageUrls.length < 3)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.add_a_photo),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
