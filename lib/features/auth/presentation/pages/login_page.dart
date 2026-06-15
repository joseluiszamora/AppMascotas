import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.appColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Spacer(flex: 2),
                _buildHero(context),
                Spacer(flex: 2),
                _buildSignInSection(context),
                SizedBox(height: 24),
                _buildFooter(context),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: context.appColors.primaryLight,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(Icons.pets, size: 52, color: AppColors.primary),
        ),
        SizedBox(height: 28),
        Text(
          'App Mascotas',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Ayuda a encontrar mascotas perdidas\nen tu comunidad.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: context.appColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInSection(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GoogleSignInButton(
              isLoading: isLoading,
              onTap: isLoading
                  ? null
                  : () => context.read<AuthBloc>().add(
                      AuthGoogleSignInRequested(),
                    ),
            ),
            SizedBox(height: 12),
            _ExploreAsGuestButton(
              isDisabled: isLoading,
              onTap: isLoading ? null : () => _returnToPublicArea(context),
            ),
          ],
        );
      },
    );
  }

  void _returnToPublicArea(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoutes.home);
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Al continuar aceptas los ',
          style: TextStyle(fontSize: 12, color: context.appColors.textHint),
        ),
        GestureDetector(
          onTap: () {
            /* TODO: abrir términos */
          },
          child: Text(
            'Términos',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          ' y la ',
          style: TextStyle(fontSize: 12, color: context.appColors.textHint),
        ),
        GestureDetector(
          onTap: () {
            /* TODO: abrir privacidad */
          },
          child: Text(
            'Privacidad',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExploreAsGuestButton extends StatelessWidget {
  const _ExploreAsGuestButton({required this.isDisabled, required this.onTap});

  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        Icons.arrow_back_rounded,
        size: 18,
        color: isDisabled
            ? context.appColors.textHint
            : context.appColors.primaryDark,
      ),
      label: Text(
        'Ahora no, seguir explorando',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDisabled
              ? context.appColors.textHint
              : context.appColors.primaryDark,
        ),
      ),
      style: TextButton.styleFrom(
        minimumSize: Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/google_logo.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (context, error, _) => Icon(
                      Icons.g_mobiledata,
                      size: 26,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Continuar con Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
