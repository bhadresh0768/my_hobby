import 'package:equatable/equatable.dart';
import '../../../common/models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, codeSent, needsRegistration, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? verificationId;
  final String? errorMessage;
  final String? phoneNumber;
  final String? registrationUid; // Add this
  final bool isGuest;
  final bool? isNewUser; // Add this

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.verificationId,
    this.errorMessage,
    this.phoneNumber,
    this.registrationUid,
    this.isGuest = false,
    this.isNewUser,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? verificationId,
    String? errorMessage,
    String? phoneNumber,
    String? registrationUid,
    bool? isGuest,
    bool? isNewUser,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      verificationId: verificationId ?? this.verificationId,
      errorMessage: errorMessage ?? this.errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      registrationUid: registrationUid ?? this.registrationUid,
      isGuest: isGuest ?? this.isGuest,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }

  @override
  List<Object?> get props => [status, user, verificationId, errorMessage, phoneNumber, registrationUid, isGuest, isNewUser];
}
