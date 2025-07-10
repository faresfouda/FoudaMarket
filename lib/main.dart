import 'package:fodamarket/views/admin/admin_dashboard_screen.dart';
import 'package:fodamarket/views/admin/data_entry_home_screen.dart';
import 'package:fodamarket/views/home/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:fodamarket/views/onbording/OnBording.dart';
import 'package:fodamarket/views/SignIn/SignIn.dart';

import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'blocs/auth/index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/products/category_bloc.dart';
// import 'package:fodamarket/views/login/Login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('main(): FirebaseAuth.currentUser = ' + FirebaseAuth.instance.currentUser.toString());
  
  runApp(FodaMarket());
}

class FodaMarket extends StatelessWidget {
  const FodaMarket({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckRequested()),
        ),
        BlocProvider<CategoryBloc>(
          create: (context) => CategoryBloc(),
        ),
      ],
      child: GetMaterialApp(
        locale: Locale('ar'),
        theme: ThemeData(fontFamily: 'Gilroy'),
        debugShowCheckedModeBanner: false,
        home: OnboardingGate(
          child: AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print('AuthWrapper: Current state is ' + state.toString());
        if (state is AuthLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is Authenticated) {
          print('AuthWrapper: Entered Authenticated block');
          print('AuthWrapper: userProfile is: ' + state.userProfile.toString());
          if (state.userProfile != null) {
            print('AuthWrapper: Navigating to home for role: ' + state.userProfile!.role.toString());
            switch (state.userProfile!.role) {
              case 'admin':
                return AdminDashboardMain();
              case 'data_entry':
                return DataEntryHomeScreen();
              default:
                return MainScreen();
            }
          } else {
            print('AuthWrapper: userProfile is null, returning MainScreen');
            return MainScreen();
          }
        } else {
          print('AuthWrapper: Showing SignIn');
          return SignIn();
        }
      },
    );
  }
}

class OnboardingGate extends StatefulWidget {
  final Widget child;
  const OnboardingGate({required this.child, super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showOnboarding = !(prefs.getBool('onboarding_seen') ?? false);
    });
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showOnboarding!) {
      return OnBording(onFinish: _completeOnboarding);
    }
    return widget.child;
  }
}


