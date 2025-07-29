import 'package:bloc/bloc.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_event.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_state.dart';
import 'package:speedgo_customer_app/auth/repository/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.login(event.phone, event.password);
        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await authRepository.logout();
      emit(AuthInitial());
    });

    on<RegistrationRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.register(
          name: event.name,
          email: event.email,
          phone: event.phone,
          password: event.password,
          passwordConfirmation: event.passwordConfirmation,
        );
        emit(AuthRegistrationSuccess(phone: event.phone));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<OtpVerificationRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.verifyOtp(
          phone: event.phone,
          otp: event.otp,
        );
        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
} 