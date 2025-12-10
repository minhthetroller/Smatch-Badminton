import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_models/auth_view_model.dart';

/// Social login buttons for Google and Facebook
class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onSuccess;
  
  const SocialLoginButtons({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Column(
          children: [
            // Google Sign In
            _SocialButton(
              icon: _buildGoogleIcon(),
              label: 'Continue with Google',
              onPressed: authViewModel.isLoading
                  ? null
                  : () => _handleGoogleSignIn(context),
              backgroundColor: Colors.white,
              textColor: Colors.grey.shade800,
              borderColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),

            // Facebook Sign In
            _SocialButton(
              icon: _buildFacebookIcon(),
              label: 'Continue with Facebook',
              onPressed: authViewModel.isLoading
                  ? null
                  : () => _handleFacebookSignIn(context),
              backgroundColor: const Color(0xFF1877F2),
              textColor: Colors.white,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }

  Widget _buildFacebookIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Color(0xFF1877F2),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.signInWithGoogle();
    
    if (success && context.mounted) {
      onSuccess?.call();
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleFacebookSignIn(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.signInWithFacebook();
    
    if (success && context.mounted) {
      onSuccess?.call();
      Navigator.of(context).pop();
    }
  }
}

/// Social login button widget
class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: borderColor ?? backgroundColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for Google logo
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double centerX = width / 2;
    final double centerY = height / 2;
    final double radius = width / 2 - 2;

    // Google colors
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);
    const blue = Color(0xFF4285F4);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Draw the G shape using arcs
    final rect = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);
    
    // Red arc (top right)
    paint.color = red;
    canvas.drawArc(rect, -0.5, 1.0, true, paint);
    
    // Yellow arc (bottom right)
    paint.color = yellow;
    canvas.drawArc(rect, 0.5, 1.0, true, paint);
    
    // Green arc (bottom left)
    paint.color = green;
    canvas.drawArc(rect, 1.5, 1.0, true, paint);
    
    // Blue arc (top left)
    paint.color = blue;
    canvas.drawArc(rect, 2.5, 1.0, true, paint);

    // Draw white center
    paint.color = Colors.white;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.55, paint);

    // Draw the horizontal bar for G
    paint.color = blue;
    canvas.drawRect(
      Rect.fromLTWH(centerX - 1, centerY - 2, radius * 0.6, 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact version for use in other places
class CompactSocialLoginButtons extends StatelessWidget {
  final VoidCallback? onSuccess;
  
  const CompactSocialLoginButtons({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google
            _CompactSocialButton(
              icon: Icons.g_mobiledata,
              backgroundColor: Colors.white,
              iconColor: Colors.red,
              onPressed: authViewModel.isLoading
                  ? null
                  : () async {
                      final success = await authViewModel.signInWithGoogle();
                      if (success && context.mounted) {
                        onSuccess?.call();
                      }
                    },
            ),
            const SizedBox(width: 16),
            // Facebook
            _CompactSocialButton(
              icon: Icons.facebook,
              backgroundColor: const Color(0xFF1877F2),
              iconColor: Colors.white,
              onPressed: authViewModel.isLoading
                  ? null
                  : () async {
                      final success = await authViewModel.signInWithFacebook();
                      if (success && context.mounted) {
                        onSuccess?.call();
                      }
                    },
            ),
          ],
        );
      },
    );
  }
}

class _CompactSocialButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onPressed;

  const _CompactSocialButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}

