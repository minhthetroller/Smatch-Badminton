import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/availability.dart';
import '../models/court.dart';
import '../view_models/booking_view_model.dart';
import '../view_models/payment_view_model.dart';
import 'booking_success_view.dart';

/// Payment view with QR code display for ZaloPay
class PaymentView extends StatelessWidget {
  final Court court;
  final String formattedDate;
  final String apiFormattedDate;
  final List<CourtBookingSummary> summaries;
  final double totalPrice;
  final String guestName;
  final String guestPhone;
  final String? guestEmail;
  final List<SubCourt> subCourts;

  const PaymentView({
    super.key,
    required this.court,
    required this.formattedDate,
    required this.apiFormattedDate,
    required this.summaries,
    required this.totalPrice,
    required this.guestName,
    required this.guestPhone,
    this.guestEmail,
    required this.subCourts,
  });

  @override
  Widget build(BuildContext context) {
    // Create booking requests for ALL selected courts, not just the first one
    final bookingRequests = summaries.map((summary) {
      return BookingRequest(
        subCourtId: _resolveSubCourtId(summary),
        startTime: summary.timeRanges.first.startTimeString,
        endTime: summary.timeRanges.last.endTimeString,
      );
    }).toList();

    return ChangeNotifierProvider(
      create: (_) => PaymentViewModel()
        ..initializePaymentForMultipleCourts(
          bookingRequests: bookingRequests,
          guestName: guestName,
          guestPhone: guestPhone,
          guestEmail: guestEmail,
          date: apiFormattedDate,
        ),
      child: _PaymentViewContent(
        court: court,
        formattedDate: formattedDate,
        summaries: summaries,
        totalPrice: totalPrice,
        guestName: guestName,
        guestPhone: guestPhone,
      ),
    );
  }

  String _resolveSubCourtId(CourtBookingSummary summary) {
    if (summary.subCourtId.isNotEmpty) return summary.subCourtId;
    if (summary.subCourtIndex >= 0 &&
        summary.subCourtIndex < subCourts.length) {
      return subCourts[summary.subCourtIndex].id;
    }
    return '';
  }
}

class _PaymentViewContent extends StatefulWidget {
  final Court court;
  final String formattedDate;
  final List<CourtBookingSummary> summaries;
  final double totalPrice;
  final String guestName;
  final String guestPhone;

  const _PaymentViewContent({
    required this.court,
    required this.formattedDate,
    required this.summaries,
    required this.totalPrice,
    required this.guestName,
    required this.guestPhone,
  });

  @override
  State<_PaymentViewContent> createState() => _PaymentViewContentState();
}

class _PaymentViewContentState extends State<_PaymentViewContent> {
  // Cache QR code bytes to prevent re-decoding on each rebuild
  Uint8List? _cachedQrBytes;
  String? _lastQrBase64;

  @override
  Widget build(BuildContext context) {
    // Only listen to state changes for navigation
    final state = context.select<PaymentViewModel, PaymentViewState>(
      (vm) => vm.state,
    );
    final viewModel = context.read<PaymentViewModel>();

    // Navigate to success screen when payment is successful
    if (state == PaymentViewState.paymentSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BookingSuccessView(
              court: widget.court,
              formattedDate: widget.formattedDate,
              summaries: widget.summaries,
              totalPrice: widget.totalPrice,
              guestName: widget.guestName,
              guestPhone: widget.guestPhone,
              bookingId: viewModel.booking?.id ?? '',
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => _handleBackPress(context, viewModel),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(context, state),
    );
  }

  void _handleBackPress(BuildContext context, PaymentViewModel viewModel) {
    if (viewModel.isPaymentActive) {
      _showCancelConfirmation(context);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Your booking will be cancelled if you leave this page. Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Stay', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back
            },
            child: const Text(
              'Cancel Payment',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PaymentViewState state) {
    switch (state) {
      case PaymentViewState.initial:
      case PaymentViewState.creatingBooking:
        return _buildLoadingState('Creating your booking...');

      case PaymentViewState.creatingPayment:
        return _buildLoadingState('Generating payment QR code...');

      case PaymentViewState.waitingForPayment:
        return _buildPaymentQRState(context);

      case PaymentViewState.paymentSuccess:
        return _buildLoadingState('Payment successful! Redirecting...');

      case PaymentViewState.paymentFailed:
        return _buildErrorState(context, isRetryable: true);

      case PaymentViewState.paymentExpired:
        return _buildExpiredState(context);

      case PaymentViewState.error:
        return _buildErrorState(context, isRetryable: false);
    }
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentQRState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Timer card - only rebuilds when timer changes
          const _TimerCard(),
          const SizedBox(height: 20),

          // QR Code card - isolated from timer rebuilds
          _QRCodeCard(
            totalPrice: widget.totalPrice,
            cachedQrBytes: _cachedQrBytes,
            onQrBytesChanged: (bytes, base64) {
              if (base64 != _lastQrBase64) {
                _cachedQrBytes = bytes;
                _lastQrBase64 = base64;
              }
            },
          ),
          const SizedBox(height: 20),

          // Order summary card - static content
          _buildOrderSummaryCard(),
          const SizedBox(height: 20),

          // Instructions card - static content
          _buildInstructionsCard(),
          const SizedBox(height: 20),

          // Refresh button
          _buildRefreshButton(context),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_outlined, color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Court name
          _buildSummaryRow('Venue', widget.court.name),
          const SizedBox(height: 8),

          // Date
          _buildSummaryRow('Date', widget.formattedDate),
          const SizedBox(height: 8),

          // Time slots
          for (final summary in widget.summaries) ...[
            _buildSummaryRow(
              summary.subCourtName,
              summary.timeRanges.map((r) => r.formatted).join(', '),
            ),
            const SizedBox(height: 8),
          ],

          // Customer info
          _buildSummaryRow('Customer', widget.guestName),
          const SizedBox(height: 8),
          _buildSummaryRow('Phone', widget.guestPhone),

          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                BookingViewModel.formatPriceVND(widget.totalPrice),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF008FE5).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF008FE5).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF008FE5), size: 20),
              SizedBox(width: 8),
              Text(
                'How to pay',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF008FE5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(1, 'Open ZaloPay app on your phone'),
          const SizedBox(height: 8),
          _buildInstructionStep(2, 'Tap "Scan QR" or use the scanner'),
          const SizedBox(height: 8),
          _buildInstructionStep(3, 'Scan the QR code above'),
          const SizedBox(height: 8),
          _buildInstructionStep(4, 'Confirm payment in the app'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF008FE5).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Color(0xFF008FE5),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.read<PaymentViewModel>().refreshPaymentStatus(),
      icon: Icon(Icons.refresh, color: Colors.grey.shade600, size: 18),
      label: Text(
        'Already paid? Tap to refresh',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
    );
  }

  Widget _buildExpiredState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_off_outlined,
                color: Colors.orange,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Expired',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The payment time has expired.\nPlease try again to complete your booking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.read<PaymentViewModel>().retryPayment(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, {required bool isRetryable}) {
    final viewModel = context.read<PaymentViewModel>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isRetryable ? 'Payment Failed' : 'Something went wrong',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              viewModel.errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (isRetryable)
              ElevatedButton.icon(
                onPressed: () => viewModel.retryPayment(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isRetryable ? 'Cancel' : 'Go Back',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timer card widget - isolated to only rebuild when timer changes
class _TimerCard extends StatelessWidget {
  const _TimerCard();

  @override
  Widget build(BuildContext context) {
    // Only select the timer-related values
    final remainingTime = context.select<PaymentViewModel, Duration>(
      (vm) => vm.remainingTime,
    );
    final formattedTime = context.select<PaymentViewModel, String>(
      (vm) => vm.formattedRemainingTime,
    );

    final isLowTime = remainingTime.inMinutes < 2;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLowTime
                ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                : [const Color(0xFF2E7D32), const Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isLowTime ? Colors.red : const Color(0xFF2E7D32))
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time remaining to pay',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            if (isLowTime)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Hurry!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// QR Code card widget - isolated from timer rebuilds
class _QRCodeCard extends StatefulWidget {
  final double totalPrice;
  final Uint8List? cachedQrBytes;
  final void Function(Uint8List? bytes, String? base64) onQrBytesChanged;

  const _QRCodeCard({
    required this.totalPrice,
    required this.cachedQrBytes,
    required this.onQrBytesChanged,
  });

  @override
  State<_QRCodeCard> createState() => _QRCodeCardState();
}

class _QRCodeCardState extends State<_QRCodeCard> {
  Uint8List? _qrBytes;

  @override
  void initState() {
    super.initState();
    _qrBytes = widget.cachedQrBytes;
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild when QR code changes, not on timer updates
    final qrBase64 = context.select<PaymentViewModel, String?>(
      (vm) => vm.paymentResponse?.qrCode.rawBase64,
    );

    // Update cached bytes if QR code changed
    if (qrBase64 != null && _qrBytes == null) {
      final viewModel = context.read<PaymentViewModel>();
      final newBytes = viewModel.qrCodeBytes;
      if (newBytes != null) {
        _qrBytes = newBytes;
        widget.onQrBytesChanged(newBytes, qrBase64);
      }
    }

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
          children: [
            // ZaloPay logo
            Image.asset(
              'assets/images/Logo FA-09.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            // QR Code - using cached bytes
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: _qrBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _qrBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback:
                            true, // Prevents flashing during rebuilds
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Amount
            Text(
              BookingViewModel.formatPriceVND(widget.totalPrice),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),

            // Scan instruction
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Scan QR code with ZaloPay app',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
