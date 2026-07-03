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

    // Initial check to move away from initial state immediately
    add(AuthUserChanged(_authRepository.currentUser?.uid));

    _userSubscription = _authRepository.userStream.listen((user) {
      add(AuthUserChanged(user?.uid));
    });
  }

  Future<void> _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) async {
    if (event.uid == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null, isGuest: false));
    } else {
      // If we are already in loading state, it means a manual sign-in is in progress.
      // We let the manual handler finish and emit the state to avoid race conditions.
      if (state.status == AuthStatus.loading) return;

      emit(state.copyWith(status: AuthStatus.loading));
      try {
        final userData = await _authRepository.getUserData(event.uid!);
        final bool isFirebaseAnonymous = _authRepository.currentUser?.isAnonymous ?? false;
        
        if (userData == null && !isFirebaseAnonymous) {
          // Firebase user exists but no Firestore data and not anonymous.
          // This happens if signup was interrupted. Treat as unauthenticated.
          emit(state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
            isGuest: false,
          ));
        } else {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: userData,
            isGuest: isFirebaseAnonymous || (userData?.role == UserRole.guest),
          ));
        }
      } catch (e) {
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
      final userCredential = await _authRepository.signInWithOtp(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
        name: event.name,
        role: event.role,
      );
      
      // Explicitly fetch user data after sign-in to ensure BLoC state is complete
      // and to avoid race conditions with the auth state stream.
      if (userCredential.user != null) {
        final userData = await _authRepository.getUserData(userCredential.user!.uid);
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: userData,
          isGuest: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSignInAnonymouslyRequested(
      AuthSignInAnonymouslyRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      await _authRepository.signInAnonymously();
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        isGuest: true,
      ));
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
