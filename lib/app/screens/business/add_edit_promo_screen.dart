import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../common/models/promo_model.dart';
import '../../bloc/promo/promo_bloc.dart';
import '../../bloc/promo/promo_event.dart';
import '../../bloc/promo/promo_state.dart';

class AddEditPromoScreen extends StatefulWidget {
  final String businessId;
  final PromoCode? promo;

  const AddEditPromoScreen({super.key, required this.businessId, this.promo});

  @override
  State<AddEditPromoScreen> createState() => _AddEditPromoScreenState();
}

class _AddEditPromoScreenState extends State<AddEditPromoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _maxUsageController;
  late TextEditingController _termsController;
  
  String _discountType = 'percentage';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.promo?.code ?? '');
    _descriptionController = TextEditingController(text: widget.promo?.description ?? '');
    _discountValueController = TextEditingController(text: widget.promo?.discountValue.toString() ?? '');
    _maxUsageController = TextEditingController(text: widget.promo?.maxUsage.toString() ?? '');
    _termsController = TextEditingController(text: widget.promo?.termsAndConditions ?? '');
    _discountType = widget.promo?.discountType ?? 'percentage';
    _startDate = widget.promo?.startDate;
    _endDate = widget.promo?.endDate;
    _isActive = widget.promo?.isActive ?? true;
    _existingImageUrls = widget.promo?.imageUrls ?? [];
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _maxUsageController.dispose();
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

      final promo = PromoCode(
        id: widget.promo?.id ?? const Uuid().v4(),
        businessId: widget.businessId,
        code: _codeController.text,
        description: _descriptionController.text,
        discountValue: double.parse(_discountValueController.text),
        discountType: _discountType,
        maxUsage: int.parse(_maxUsageController.text),
        currentUsage: widget.promo?.currentUsage ?? 0,
        startDate: _startDate,
        endDate: _endDate,
        imageUrls: _existingImageUrls,
        termsAndConditions: _termsController.text,
        isActive: _isActive,
      );

      if (widget.promo == null) {
        context.read<PromoBloc>().add(PromoCreateRequested(promo, images: _newImages));
      } else {
        context.read<PromoBloc>().add(PromoUpdateRequested(promo, newImages: _newImages));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.promo == null ? 'Add Promo Code' : 'Edit Promo Code')),
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
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Promo Code (e.g. SAVE50)', border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Enter code' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                  validator: (val) => val!.isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountValueController,
                        decoration: const InputDecoration(labelText: 'Discount Value', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (val) => val!.isEmpty ? 'Enter value' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _discountType,
                      items: const [
                        DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                      ],
                      onChanged: (val) => setState(() => _discountType = val!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxUsageController,
                  decoration: const InputDecoration(labelText: 'Max Usage (First N People)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? 'Enter limit' : null,
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
                    child: Text(widget.promo == null ? 'Create Promo' : 'Save Changes'),
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
