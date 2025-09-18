import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/index.dart';
import '../views/auth/auth_selection_screen.dart';
import '../views/admin/dashboard_screen.dart';
import '../views/admin/data_entry_home_screen.dart';
import '../views/home/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print('AuthWrapper: Current state is $state');
        if (state is AuthLoading) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is Authenticated) {
          print('AuthWrapper: Entered Authenticated block');
          print('AuthWrapper: userProfile is: ${state.userProfile}');
          if (state.userProfile != null) {
            print(
              'AuthWrapper: Navigating to home for role: ${state.userProfile!.role}',
            );
            switch (state.userProfile!.role) {
              case 'admin':
                return DashboardScreen();
              case 'data_entry':
                return DataEntryHomeScreen();
              case 'user':
              default:
                return MainScreen();
            }
          } else {
            print('AuthWrapper: userProfile is null, returning MainScreen');
            return MainScreen();
          }
        } else {
          print('AuthWrapper: Showing SignIn');
          return AuthSelectionScreen();
        }
      },
    );
  }
}
