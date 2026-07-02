import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../common/models/business_model.dart';
import '../../../common/utils/validators.dart';
import '../../../core/app_constants.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/business/business_bloc.dart';
import '../../bloc/business/business_event.dart';
import '../../bloc/business/business_state.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

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
  
  String _selectedCategory = AppConstants.businessCategories.first;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Your Business')),
      body: BlocListener<BusinessBloc, BusinessState>(
        listener: (context, state) {
          if (state.status == BusinessStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Business Registered Successfully!')),
            );
            Navigator.of(context).pop();
          } else if (state.status == BusinessStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Registration Failed')),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
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
                title: const Text('Location Details'),
                isActive: _currentStep >= 1,
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
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement Map Picker
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Pick Location on Map'),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Contact Details'),
                isActive: _currentStep >= 2,
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
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState.user == null) return;

      final business = Business(
        id: const Uuid().v4(),
        ownerId: authState.user!.uid,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        location: _addressController.text.trim(),
        city: _cityController.text.trim(),
        zipcode: _zipcodeController.text.trim(),
        country: _countryController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        email: _emailController.text.trim(),
        latitude: 0.0,
        longitude: 0.0,
      );

      context.read<BusinessBloc>().add(BusinessRegisterRequested(business));
    }
  }
}
