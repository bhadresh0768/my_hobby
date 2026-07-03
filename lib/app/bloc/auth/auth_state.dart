import 'package:equatable/equatable.dart';
import '../../../common/models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, codeSent, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? verificationId;
  final String? errorMessage;
  final String? phoneNumber;
  final bool isGuest; // Explicitly track guest status

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.verificationId,
    this.errorMessage,
    this.phoneNumber,
    this.isGuest = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? verificationId,
    String? errorMessage,
    String? phoneNumber,
    bool? isGuest,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      verificationId: verificationId ?? this.verificationId,
      errorMessage: errorMessage ?? this.errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  List<Object?> get props => [status, user, verificationId, errorMessage, phoneNumber, isGuest];
}
