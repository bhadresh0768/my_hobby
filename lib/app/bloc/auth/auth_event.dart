import 'package:equatable/equatable.dart';
import '../../../common/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthUserChanged extends AuthEvent {
  final String? uid;
  AuthUserChanged(this.uid);
  @override
  List<Object?> get props => [uid];
}

class AuthPhoneVerificationRequested extends AuthEvent {
  final String phoneNumber;
  AuthPhoneVerificationRequested(this.phoneNumber);
  @override
  List<Object?> get props => [phoneNumber];
}

class AuthOtpSubmitted extends AuthEvent {
  final String verificationId;
  final String smsCode;
  final String name;
  final UserRole role;
  
  AuthOtpSubmitted({
    required this.verificationId,
    required this.smsCode,
    required this.name,
    required this.role,
  });
  
  @override
  List<Object?> get props => [verificationId, smsCode, name, role];
}

class AuthCodeSent extends AuthEvent {
  final String verificationId;
  final int? resendToken;
  final bool isNewUser;
  
  AuthCodeSent(this.verificationId, this.resendToken, this.isNewUser);
  
  @override
  List<Object?> get props => [verificationId, resendToken, isNewUser];
}

class AuthVerificationFailed extends AuthEvent {
  final String message;
  AuthVerificationFailed(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthSignInAnonymouslyRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String displayName;
  final dynamic imageFile; // Use dynamic to avoid mandatory dart:io import if needed in some contexts, but usually File is fine.

  AuthProfileUpdateRequested({required this.displayName, this.imageFile});

  @override
  List<Object?> get props => [displayName, imageFile];
}

class AuthToggleFavoriteRequested extends AuthEvent {
  final String businessId;

  AuthToggleFavoriteRequested(this.businessId);

  @override
  List<Object?> get props => [businessId];
}
