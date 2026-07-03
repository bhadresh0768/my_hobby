import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../common/widgets/custom_button.dart';
import '../../../common/utils/validators.dart';
import '../../../common/models/user_model.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;

  @override
  void dispose() {
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Number')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated && !state.isGuest) {
            // Close the verification screen and go back to home/profile
            Navigator.of(context).pop(); 
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Verification Error')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Enter the code sent to ${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: '6-Digit OTP',
                    prefixIcon: Icon(Icons.security),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) => Validators.validateRequired(value, 'OTP'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Name'),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Login as:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                RadioGroup<UserRole>(
                  groupValue: _selectedRole,
                  onChanged: (value) => setState(() => _selectedRole = value!),
                  child: Row(
                    children: const [
                      Expanded(
                        child: RadioListTile<UserRole>(
                          title: Text('Customer'),
                          value: UserRole.customer,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<UserRole>(
                          title: Text('Business'),
                          value: UserRole.businessOwner,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return CustomButton(
                      text: 'Verify & Login',
                      isLoading: state.status == AuthStatus.loading,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<AuthBloc>().add(
                                AuthOtpSubmitted(
                                  verificationId: widget.verificationId,
                                  smsCode: _otpController.text.trim(),
                                  name: _nameController.text.trim(),
                                  role: _selectedRole,
                                ),
                              );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
