import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../view_models/auth_view_model.dart';

/// Booking history view with paginated list
class BookingHistoryView extends StatefulWidget {
  const BookingHistoryView({super.key});

  @override
  State<BookingHistoryView> createState() => _BookingHistoryViewState();
}

class _BookingHistoryViewState extends State<BookingHistoryView> {
  final ScrollController _scrollController = ScrollController();
  
  BookingHistoryResponse? _historyResponse;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  BookingStatus? _statusFilter;
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreBookings();
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    final authViewModel = context.read<AuthViewModel>();
    final response = await authViewModel.getBookingHistory(
      page: _currentPage,
      limit: _pageSize,
      status: _statusFilter,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _historyResponse = response;
        if (response == null) {
          _error = 'Failed to load bookings';
        }
      });
    }
  }

  Future<void> _loadMoreBookings() async {
    if (_isLoadingMore || _historyResponse == null) return;
    if (!_historyResponse!.pagination.hasNext) return;

    setState(() => _isLoadingMore = true);

    final authViewModel = context.read<AuthViewModel>();
    final response = await authViewModel.getBookingHistory(
      page: _currentPage + 1,
      limit: _pageSize,
      status: _statusFilter,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (response != null) {
          _currentPage++;
          _historyResponse = BookingHistoryResponse(
            bookings: [..._historyResponse!.bookings, ...response.bookings],
            pagination: response.pagination,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Booking History',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Filter button
          PopupMenuButton<BookingStatus?>(
            icon: Badge(
              isLabelVisible: _statusFilter != null,
              child: const Icon(Icons.filter_list, color: AppTheme.textPrimary),
            ),
            onSelected: (status) {
              setState(() => _statusFilter = status);
              _loadBookings();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<BookingStatus?>(
                value: null,
                child: Text('All Bookings'),
              ),
              ...BookingStatus.values.map((status) {
                return PopupMenuItem<BookingStatus>(
                  value: status,
                  child: Row(
                    children: [
                      _buildStatusDot(status),
                      const SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_historyResponse == null || _historyResponse!.bookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _historyResponse!.bookings.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _historyResponse!.bookings.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                ),
              ),
            );
          }
          return _buildBookingCard(_historyResponse!.bookings[index]);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 48,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusFilter != null
                  ? 'No ${_statusFilter!.displayName.toLowerCase()} bookings'
                  : 'No bookings yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusFilter != null
                  ? 'Try changing the filter or check back later'
                  : 'Your booking history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (_statusFilter != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() => _statusFilter = null);
                  _loadBookings();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filter'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingHistoryItem booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header with court name and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Court icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_tennis,
                    color: Color(0xFF2E7D32),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Court info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.court.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.subCourt.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                _buildStatusBadge(booking.status),
              ],
            ),
          ),

          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Date and time row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: _formatDate(booking.date),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: '${booking.startTime} - ${booking.endTime}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Location and price row
                Row(
                  children: [
                    if (booking.court.addressDistrict != null)
                      Expanded(
                        child: _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'Location',
                          value: booking.court.addressDistrict!,
                        ),
                      ),
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.payments,
                        label: 'Total',
                        value: _formatPrice(booking.totalPrice),
                        valueColor: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),

                // Notes if any
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Footer with booking date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  'Booked on ${_formatDateTime(booking.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${booking.id.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusDot(status),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(BookingStatus status) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return const Color(0xFF2E7D32);
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final bookingDate = DateTime(date.year, date.month, date.day);

    if (bookingDate == today) {
      return 'Today';
    } else if (bookingDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEE, dd MMM').format(date);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)} ₫';
  }
}

