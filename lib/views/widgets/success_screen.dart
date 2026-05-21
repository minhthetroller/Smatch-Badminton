import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// A detail item to display in the success screen
class SuccessDetailItem {
  final IconData icon;
  final String label;
  final String value;

  const SuccessDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// An action button configuration for the success screen
class SuccessActionButton {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const SuccessActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}

/// A tip/next step item for the success screen
class SuccessNextStep {
  final IconData icon;
  final String text;

  const SuccessNextStep({
    required this.icon,
    required this.text,
  });
}

/// Shared success screen widget used for booking confirmations, match payments, etc.
class SuccessScreen extends StatefulWidget {
  /// Main title displayed after success animation (e.g., "Booking Confirmed! 🎉")
  final String title;
  
  /// Subtitle displayed below the title
  final String subtitle;
  
  /// Reference ID (e.g., booking ID, match ID)
  final String? referenceId;
  
  /// Label for reference ID (e.g., "Booking Reference", "Match Reference")
  final String referenceLabel;
  
  /// Total amount paid (null for free items)
  final double? amount;
  
  /// Function to format the price
  final String Function(double)? formatPrice;
  
  /// List of detail items to display
  final List<SuccessDetailItem> details;
  
  /// List of next step tips
  final List<SuccessNextStep> nextSteps;
  
  /// Action buttons at the bottom
  final List<SuccessActionButton> actions;
  
  /// Callback when user tries to go back
  final VoidCallback? onBack;
  
  /// Primary color for success elements (defaults to green)
  final Color successColor;

  const SuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.referenceId,
    this.referenceLabel = 'Reference',
    this.amount,
    this.formatPrice,
    this.details = const [],
    this.nextSteps = const [],
    this.actions = const [],
    this.onBack,
    this.successColor = const Color(0xFF2E7D32),
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    
    // Haptic feedback on success
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _defaultFormatPrice(double price) {
    if (price == 0) return 'Miễn phí';
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}đ';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Success animation
                      _buildSuccessAnimation(),
                      const SizedBox(height: 32),

                      // Success message
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildSuccessMessage(),
                      ),
                      const SizedBox(height: 32),

                      // Details card
                      if (widget.details.isNotEmpty || widget.referenceId != null || widget.amount != null)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildDetailsCard(),
                        ),
                      
                      if (widget.nextSteps.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildNextStepsCard(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              if (widget.actions.isNotEmpty)
                _buildBottomButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.successColor.withValues(alpha: 0.9),
              widget.successColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.successColor.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with reference ID
          if (widget.referenceId != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.confirmation_number_outlined,
                    color: widget.successColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.referenceLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.referenceId!.length > 8
                            ? '${widget.referenceId!.substring(0, 8).toUpperCase()}...'
                            : widget.referenceId!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.referenceId!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reference ID copied!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
          ],

          // Detail rows
          for (int i = 0; i < widget.details.length; i++) ...[
            _buildDetailRow(
              icon: widget.details[i].icon,
              label: widget.details[i].label,
              value: widget.details[i].value,
            ),
            if (i < widget.details.length - 1) const SizedBox(height: 16),
          ],

          // Total amount
          if (widget.amount != null) ...[
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.successColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PAID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.formatPrice?.call(widget.amount!) ?? _defaultFormatPrice(widget.amount!),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.successColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade400,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.successColor.withValues(alpha: 0.05),
            widget.successColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.successColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: widget.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'What\'s Next?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < widget.nextSteps.length; i++) ...[
            _buildNextStep(
              icon: widget.nextSteps[i].icon,
              text: widget.nextSteps[i].text,
            ),
            if (i < widget.nextSteps.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildNextStep({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: widget.successColor.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < widget.actions.length; i++) ...[
            Expanded(
              child: widget.actions[i].isPrimary
                  ? ElevatedButton(
                      onPressed: widget.actions[i].onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.actions[i].label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: widget.actions[i].onPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.successColor,
                        side: BorderSide(color: widget.successColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.actions[i].label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
            if (i < widget.actions.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}
