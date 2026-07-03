import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/models/user_model.dart';
import '../../../core/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _userSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthUserChanged>(_onUserChanged);
    on<AuthPhoneVerificationRequested>(_onPhoneVerificationRequested);
    on<AuthCodeSent>(_onCodeSent);
    on<AuthVerificationFailed>(_onVerificationFailed);
    on<AuthOtpSubmitted>(_onOtpSubmitted);
    on<AuthSignInAnonymouslyRequested>(_onSignInAnonymouslyRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);

    _userSubscription = _authRepository.userStream.listen((user) {
      add(AuthUserChanged(user?.uid));
    });
  }

  Future<void> _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) async {
    if (event.uid == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null, isGuest: false));
    } else {
      emit(state.copyWith(status: AuthStatus.loading));
      try {
        final userData = await _authRepository.getUserData(event.uid!);
        // If we have data in Firestore, it's a real user. 
        // If not, it's an anonymous/guest session.
        final bool isGuest = userData == null || userData.role == UserRole.guest;
        
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: userData,
          isGuest: isGuest,
        ));
      } catch (e) {
        // Fallback for anonymous auth if Firestore fetch fails
        emit(state.copyWith(
          status: AuthStatus.authenticated, 
          isGuest: true,
          errorMessage: e.toString()
        ));
      }
    }
  }

  Future<void> _onPhoneVerificationRequested(
      AuthPhoneVerificationRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading, phoneNumber: event.phoneNumber));
    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          add(AuthCodeSent(verificationId, resendToken));
        },
        onVerificationFailed: (e) {
          add(AuthVerificationFailed(e.message ?? 'Verification Failed'));
        },
        onVerificationCompleted: (credential) async {
          // Auto-resolution handling could go here
        },
      );
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  void _onCodeSent(AuthCodeSent event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      status: AuthStatus.codeSent,
      verificationId: event.verificationId,
    ));
  }

  void _onVerificationFailed(AuthVerificationFailed event, Emitter<AuthState> emit) {
    emit(state.copyWith(status: AuthStatus.error, errorMessage: event.message));
  }

  Future<void> _onOtpSubmitted(AuthOtpSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.signInWithOtp(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
        name: event.name,
        role: event.role,
      );
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSignInAnonymouslyRequested(
      AuthSignInAnonymouslyRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.signInAnonymously();
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSignOutRequested(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
