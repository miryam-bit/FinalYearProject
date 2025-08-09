import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_bloc.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_event.dart';
import 'package:speedgo_customer_app/auth/bloc/auth_state.dart';
import 'package:speedgo_customer_app/auth/repository/auth_repository.dart';
import 'package:speedgo_customer_app/auth/screens/login_screen.dart';
import 'package:speedgo_customer_app/auth/screens/otp_screen.dart';
import 'package:speedgo_customer_app/auth/screens/registration_screen.dart';
import 'package:speedgo_customer_app/features/home/screens/home_screen.dart';
import 'package:speedgo_customer_app/features/profile/screens/profile_screen.dart';
import 'package:speedgo_customer_app/features/profile/screens/ride_history_screen.dart';
import 'package:speedgo_customer_app/features/profile/screens/settings_screen.dart';
import 'package:speedgo_customer_app/features/profile/screens/edit_profile_screen.dart';
import 'package:speedgo_customer_app/features/profile/screens/emergency_contacts_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(authRepository: AuthRepository()),
      child: MaterialApp(
        title: 'SpeedGo Customer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/ride-history': (context) => const RideHistoryScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/emergency-contacts': (context) => const EmergencyContactsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      },
      child: const LoginScreen(),
    );
  }
}
