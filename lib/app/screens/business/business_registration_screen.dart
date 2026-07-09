import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../common/models/business_model.dart';
import '../../../common/utils/validators.dart';
import '../../../core/app_constants.dart';
import '../../../core/repositories/business_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/business/business_bloc.dart';
import '../../bloc/business/business_event.dart';
import '../../bloc/business/business_state.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  final Business? business;

  const BusinessRegistrationScreen({super.key, this.business});

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipcodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _customCategoryController = TextEditingController();
  
  String _selectedCategory = AppConstants.businessCategories.first;
  final List<String> _imageUrls = [];
  final List<File> _newImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.business != null) {
      _nameController.text = widget.business!.name;
      _descriptionController.text = widget.business!.description;
      _addressController.text = widget.business!.location;
      _cityController.text = widget.business!.city;
      _zipcodeController.text = widget.business!.zipcode;
      _countryController.text = widget.business!.country;
      _phoneController.text = widget.business!.phoneNumber;
      _whatsappController.text = widget.business!.whatsappNumber;
      _emailController.text = widget.business!.email;
      
      if (AppConstants.businessCategories.contains(widget.business!.category)) {
        _selectedCategory = widget.business!.category;
      } else {
        _selectedCategory = 'Other';
        _customCategoryController.text = widget.business!.category;
      }
      _imageUrls.addAll(widget.business!.imageUrls);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipcodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    // Show Source Selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (!mounted) return;
      
      final primaryColor = Theme.of(context).primaryColor;
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Business Photo',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Business Photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _newImages.add(File(croppedFile.path));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.business != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Business' : 'Register Your Business')),
      body: Stack(
        children: [
          BlocListener<BusinessBloc, BusinessState>(
            listener: (context, state) {
              if (state.status == BusinessStatus.submissionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEdit ? 'Business Updated Successfully!' : 'Business Registered Successfully!')),
                );
                Navigator.of(context).pop();
              } else if (state.status == BusinessStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage ?? 'Operation Failed')),
                );
              }
            },
            child: Form(
              key: _formKey,
              child: Stepper(
                physics: const ClampingScrollPhysics(),
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep += 1);
                  } else {
                    _submitForm();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  }
                },
                steps: [
                  Step(
                    title: const Text('Basic Information'),
                    isActive: _currentStep >= 0,
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Business Name'),
                          validator: (value) => Validators.validateRequired(value, 'Name'),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: AppConstants.businessCategories.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedCategory = value!),
                        ),
                        if (_selectedCategory == 'Other') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customCategoryController,
                            decoration: const InputDecoration(
                              labelText: 'Custom Category Name',
                              hintText: 'e.g. Handmade Crafts',
                            ),
                            validator: (value) => _selectedCategory == 'Other'
                                ? Validators.validateRequired(value, 'Category Name')
                                : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          validator: (value) => Validators.validateRequired(value, 'Description'),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Images'),
                    isActive: _currentStep >= 1,
                    content: Column(
                      children: [
                        const Text('Upload photos of your business (storefront, products, etc.)'),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._imageUrls.map((url) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _imageUrls.remove(url)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                            ..._newImages.map((file) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    file,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _newImages.remove(file)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                            if (_imageUrls.length + _newImages.length < 5)
                              InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[400]!),
                                  ),
                                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Location Details'),
                    isActive: _currentStep >= 2,
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Full Address'),
                          validator: (value) => Validators.validateRequired(value, 'Address'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(labelText: 'City'),
                                validator: (value) => Validators.validateRequired(value, 'City'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _zipcodeController,
                                decoration: const InputDecoration(labelText: 'Zipcode'),
                                validator: (value) => Validators.validateRequired(value, 'Zipcode'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(labelText: 'Country'),
                          validator: (value) => Validators.validateRequired(value, 'Country'),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Contact Details'),
                    isActive: _currentStep >= 3,
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number'),
                          keyboardType: TextInputType.phone,
                          validator: Validators.validatePhone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _whatsappController,
                          decoration: const InputDecoration(labelText: 'WhatsApp Number'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Business Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            const ModalBarrier(
              dismissible: false,
              color: Colors.black54,
            ),
          if (_isUploading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_isUploading) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      
      final authState = context.read<AuthBloc>().state;
      final businessBloc = context.read<BusinessBloc>(); // Capture Bloc here
      if (authState.user == null) {
        setState(() => _isUploading = false);
        return;
      }

      final businessId = widget.business?.id ?? const Uuid().v4();
      final repository = context.read<BusinessRepository>();

      try {
        // Upload new images
        final uploadedUrls = await Future.wait(
          _newImages.map((file) => repository.uploadBusinessImage(businessId, file))
        );

        final business = Business(
          id: businessId,
          ownerId: authState.user!.uid,
          name: _nameController.text.trim(),
          category: _selectedCategory == 'Other'
              ? _customCategoryController.text.trim()
              : _selectedCategory,
          description: _descriptionController.text.trim(),
          location: _addressController.text.trim(),
          city: _cityController.text.trim(),
          zipcode: _zipcodeController.text.trim(),
          country: _countryController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          whatsappNumber: _whatsappController.text.trim(),
          email: _emailController.text.trim(),
          imageUrls: [..._imageUrls, ...uploadedUrls],
          latitude: widget.business?.latitude ?? 0.0,
          longitude: widget.business?.longitude ?? 0.0,
          isVerified: widget.business?.isVerified ?? false,
          averageRating: widget.business?.averageRating ?? 0.0,
          totalReviews: widget.business?.totalReviews ?? 0,
        );

        if (widget.business != null) {
          businessBloc.add(BusinessUpdateRequested(business));
        } else {
          businessBloc.add(BusinessRegisterRequested(business));
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          if (errorMessage.contains('403') || errorMessage.contains('Permission denied')) {
            errorMessage = 'Permission denied: Please ensure your Firebase Storage rules allow uploads.';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Upload Error'),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }
}
