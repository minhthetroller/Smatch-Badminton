import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/match.dart';
import '../../services/match_service.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/match_view_model.dart';
import 'match_success_screen.dart';

/// Payment state for the match payment flow
enum PaymentState {
  initial, // Initial state, showing match info
  creatingPayment, // Creating payment with ZaloPay
  waitingForPayment, // Showing QR code, waiting for user to pay
  verifyingPayment, // Verifying payment status
  success, // Payment successful
  failed, // Payment failed or expired
}

/// Dedicated payment screen for joining a match
/// Requires 100% upfront payment via ZaloPay
class MatchPaymentView extends StatefulWidget {
  final MatchWithDetails match;

  const MatchPaymentView({super.key, required this.match});

  @override
  State<MatchPaymentView> createState() => _MatchPaymentViewState();
}

class _MatchPaymentViewState extends State<MatchPaymentView> {
  final MatchService _matchService = MatchService();
  
  PaymentState _paymentState = PaymentState.initial;
  MatchPaymentResponse? _paymentResponse;
  String? _errorMessage;
  Timer? _statusPollingTimer;
  Timer? _expirationTimer;
  Duration? _timeRemaining;
  bool _accessDenied = false;

  @override
  void initState() {
    super.initState();
    _validateAccess();
  }

  /// Validate that user can access payment for this match
  /// For private matches, user must have PENDING_PAYMENT or ACCEPTED status (host approved)
  void _validateAccess() {
    if (!widget.match.isPrivate) return; // Public matches don't need validation
    
    final authVM = context.read<AuthViewModel>();
    final userId = authVM.user?.id;
    if (userId == null) {
      _accessDenied = true;
      return;
    }
    
    // Check player status in match
    final playerInMatch = widget.match.players.where(
      (p) => p.userId == userId
    ).firstOrNull;
    
    if (playerInMatch == null) {
      // User hasn't requested to join yet - shouldn't be on payment screen
      _accessDenied = true;
      return;
    }
    
    // For private matches, only PENDING_PAYMENT or ACCEPTED status can proceed to payment
    final status = playerInMatch.status;
    if (status != MatchPlayerStatus.pendingPayment && 
        status != MatchPlayerStatus.accepted) {
      _accessDenied = true;
    }
  }

  String _formatPrice(int price) {
    if (price == 0) return 'Miễn phí';
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)}đ';
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('EEEE, dd/MM/yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _expirationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show access denied for private matches without host approval
    if (_accessDenied) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Access Denied',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
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
                    Icons.lock_outline,
                    color: Colors.orange,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Waiting for Approval',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This is a private match. You need host approval before you can proceed to payment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _paymentState == PaymentState.success
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: _canGoBack() ? () => Navigator.of(context).pop() : null,
              ),
              title: Text(
                _getAppBarTitle(),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  bool _canGoBack() {
    return _paymentState == PaymentState.initial || 
           _paymentState == PaymentState.failed;
  }

  String _getAppBarTitle() {
    switch (_paymentState) {
      case PaymentState.initial:
        return 'Thanh toán';
      case PaymentState.creatingPayment:
        return 'Đang tạo thanh toán...';
      case PaymentState.waitingForPayment:
        return 'Quét mã QR';
      case PaymentState.verifyingPayment:
        return 'Đang xác nhận...';
      case PaymentState.success:
        return 'Thành công';
      case PaymentState.failed:
        return 'Thanh toán thất bại';
    }
  }

  Widget _buildBody() {
    switch (_paymentState) {
      case PaymentState.initial:
        return _buildInitialView();
      case PaymentState.creatingPayment:
        return _buildLoadingView('Đang tạo thanh toán...');
      case PaymentState.waitingForPayment:
        return _buildQRCodeView();
      case PaymentState.verifyingPayment:
        return _buildLoadingView('Đang xác nhận thanh toán...');
      case PaymentState.success:
        // Navigate to success screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToSuccessScreen();
        });
        return _buildLoadingView('Đang chuyển trang...');
      case PaymentState.failed:
        return _buildFailedView();
    }
  }
  
  void _navigateToSuccessScreen() {
    if (!mounted) return;
    // Use pushReplacement to prevent going back to payment view
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MatchSuccessScreen(
          match: widget.match,
          amountPaid: widget.match.price > 0 ? widget.match.price.toDouble() : null,
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchInfoCard(),
          const SizedBox(height: 20),
          _buildPaymentDetails(),
          const SizedBox(height: 20),
          _buildPaymentMethod(),
          const SizedBox(height: 20),
          _buildTermsSection(),
        ],
      ),
    );
  }

  Widget _buildLoadingView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeView() {
    if (_paymentResponse == null) {
      return _buildLoadingView('Đang tải mã QR...');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Timer
          if (_timeRemaining != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _timeRemaining!.inMinutes < 2 
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 18,
                    color: _timeRemaining!.inMinutes < 2 ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Còn lại: ${_formatDuration(_timeRemaining!)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _timeRemaining!.inMinutes < 2 ? Colors.red : Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // QR Code
          Container(
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
                const Text(
                  'Quét mã QR bằng ZaloPay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Số tiền: ${_formatPrice(widget.match.price)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                
                // QR Code Image
                _buildQRImage(),
                
                const SizedBox(height: 24),
                const Text(
                  'Mở ứng dụng ZaloPay và quét mã QR để thanh toán',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Refresh status button
          OutlinedButton.icon(
            onPressed: _checkPaymentStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Kiểm tra trạng thái'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRImage() {
    final qrCode = _paymentResponse?.qrCode;
    if (qrCode == null) {
      return Container(
        width: 250,
        height: 250,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.qr_code, size: 100, color: Colors.grey),
        ),
      );
    }

    // Try to decode base64 image
    try {
      String base64Data = qrCode.rawBase64;
      // Remove data URI prefix if present
      if (base64Data.contains(',')) {
        base64Data = base64Data.split(',').last;
      }
      final bytes = base64Decode(base64Data);
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.memory(
          bytes,
          width: 250,
          height: 250,
          fit: BoxFit.contain,
        ),
      );
    } catch (e) {
      // Fallback to placeholder
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Không thể hiển thị mã QR',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFailedView() {
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
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Thanh toán thất bại',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi trong quá trình thanh toán',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _retryPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchInfoCard() {
    return Container(
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_tennis,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.match.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Host: ${widget.match.host?.displayName ?? "Unknown"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.calendar_today, 'Ngày', _formatDate(widget.match.date)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, 'Thời gian', '${widget.match.startTime} - ${widget.match.endTime}'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Sân', widget.match.court?.name ?? 'Unknown'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.bar_chart, 'Trình độ', widget.match.skillLevel.displayName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.people, 'Hình thức', widget.match.playerFormat.displayName),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
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
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentRow('Phí tham gia', _formatPrice(widget.match.price)),
          const Divider(height: 24),
          _buildPaymentRow(
            'Tổng thanh toán (100%)',
            _formatPrice(widget.match.price),
            isBold: true,
            valueColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            color: valueColor ?? AppTheme.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
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
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'ZP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ZaloPay',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Quét mã QR để thanh toán',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Lưu ý',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Yêu cầu thanh toán 100% để xác nhận chỗ\n'
            '• Không hoàn tiền nếu hủy trong vòng 24 giờ\n'
            '• Tiền sẽ được hoàn lại nếu host hủy trận',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    // Hide bottom bar for certain states
    if (_paymentState == PaymentState.creatingPayment ||
        _paymentState == PaymentState.verifyingPayment ||
        _paymentState == PaymentState.success ||
        _paymentState == PaymentState.failed) {
      return null;
    }

    // QR code view has cancel button
    if (_paymentState == PaymentState.waitingForPayment) {
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _cancelPayment,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Hủy thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    // Initial state - show pay button
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(widget.match.price),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.match.price > 0 ? 'Thanh toán' : 'Tham gia miễn phí',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startPayment() async {
    // For free matches, just join directly
    if (widget.match.price == 0) {
      await _joinFreeMatch();
      return;
    }

    // For paid matches, create ZaloPay payment
    setState(() => _paymentState = PaymentState.creatingPayment);

    try {
      // Refresh auth token
      final authVM = context.read<AuthViewModel>();
      await authVM.refreshAuthToken();

      // Create payment
      final response = await _matchService.createMatchJoinPayment(widget.match.id);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _paymentResponse = response.data;
          _paymentState = PaymentState.waitingForPayment;
        });

        // Start expiration countdown
        _startExpirationTimer();
        
        // Start polling for payment status
        _startStatusPolling();
      } else {
        setState(() {
          _paymentState = PaymentState.failed;
          _errorMessage = response.error?.message ?? 'Không thể tạo thanh toán';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paymentState = PaymentState.failed;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _joinFreeMatch() async {
    setState(() => _paymentState = PaymentState.creatingPayment);

    // Capture ViewModels before async operations to avoid BuildContext async gap
    final authVM = context.read<AuthViewModel>();
    final matchVM = context.read<MatchViewModel>();

    try {
      await authVM.refreshAuthToken();
      await matchVM.joinMatch(widget.match.id);

      if (mounted) {
        setState(() => _paymentState = PaymentState.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paymentState = PaymentState.failed;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _startExpirationTimer() {
    final expireAt = _paymentResponse?.expireAt;
    if (expireAt == null) return;

    // Calculate initial time remaining
    _updateTimeRemaining(expireAt);

    // Update every second
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining(expireAt);
    });
  }

  void _updateTimeRemaining(DateTime expireAt) {
    final now = DateTime.now();
    final remaining = expireAt.difference(now);

    if (remaining.isNegative) {
      _expirationTimer?.cancel();
      _statusPollingTimer?.cancel();
      if (mounted) {
        setState(() {
          _paymentState = PaymentState.failed;
          _errorMessage = 'Thời gian thanh toán đã hết hạn';
        });
      }
    } else {
      if (mounted) {
        setState(() => _timeRemaining = remaining);
      }
    }
  }

  void _startStatusPolling() {
    // Poll every 3 seconds
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_paymentResponse == null) return;

    try {
      final response = await _matchService.queryMatchPaymentStatus(
        widget.match.id,
        _paymentResponse!.payment.id,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final status = response.data!.status;
        
        if (status == MatchPaymentStatus.success) {
          _statusPollingTimer?.cancel();
          _expirationTimer?.cancel();
          setState(() => _paymentState = PaymentState.success);
        } else if (status == MatchPaymentStatus.failed || 
                   status == MatchPaymentStatus.expired) {
          _statusPollingTimer?.cancel();
          _expirationTimer?.cancel();
          setState(() {
            _paymentState = PaymentState.failed;
            _errorMessage = status == MatchPaymentStatus.expired 
                ? 'Thanh toán đã hết hạn'
                : 'Thanh toán thất bại';
          });
        }
      }
    } catch (e) {
      // Silently fail on polling errors
      debugPrint('Payment status check failed: $e');
    }
  }

  void _cancelPayment() {
    _statusPollingTimer?.cancel();
    _expirationTimer?.cancel();
    Navigator.of(context).pop();
  }

  void _retryPayment() {
    setState(() {
      _paymentState = PaymentState.initial;
      _paymentResponse = null;
      _errorMessage = null;
      _timeRemaining = null;
    });
  }
}
