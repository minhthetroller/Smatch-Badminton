import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/court.dart';
import '../view_models/booking_view_model.dart';
import 'booking_confirmation_view.dart';

/// Booking view with timeline selector for court reservations
class BookingView extends StatelessWidget {
  final Court court;

  const BookingView({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingViewModel(court: court)..initialize(),
      child: const _BookingViewContent(),
    );
  }
}

class _BookingViewContent extends StatelessWidget {
  const _BookingViewContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and date picker
            const _BookingHeader(),

            // Sub-court tabs
            const _SubCourtTabs(),

            // Timeline grid
            const Expanded(child: _TimelineGrid()),

            // Bottom booking bar
            const _BottomBookingBar(),
          ],
        ),
      ),
    );
  }
}

/// Header with back button, title, and date picker
class _BookingHeader extends StatelessWidget {
  const _BookingHeader();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),

          // Title
          const Text(
            'Booking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),

          const Spacer(),

          // Date picker button
          InkWell(
            onTap: () => _showDatePicker(context, viewModel),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    viewModel.formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down,
                      size: 20, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(
      BuildContext context, BookingViewModel viewModel) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      viewModel.selectDate(picked);
    }
  }
}

/// Tab bar for sub-courts with selection indicator
class _SubCourtTabs extends StatelessWidget {
  const _SubCourtTabs();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingViewModel>();
    final subCourts = viewModel.subCourts;

    if (subCourts.isEmpty) {
      return const SizedBox(height: 48);
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subCourts.length,
        itemBuilder: (context, index) {
          final isViewing = viewModel.selectedSubCourtIndex == index;
          final hasSelections =
              viewModel.selection.slotsByCourtIndex.containsKey(index);
          final selectionCount = viewModel.selection.slotsByCourtIndex[index]?.length ?? 0;

          return GestureDetector(
            onTap: () => viewModel.selectSubCourt(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color:
                        isViewing ? const Color(0xFF2E7D32) : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subCourts[index].name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isViewing ? FontWeight.w600 : FontWeight.normal,
                      color: isViewing
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (hasSelections) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$selectionCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Timeline grid with 30-minute time slots
class _TimelineGrid extends StatefulWidget {
  const _TimelineGrid();

  @override
  State<_TimelineGrid> createState() => _TimelineGridState();
}

class _TimelineGridState extends State<_TimelineGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final viewModel = context.read<BookingViewModel>();

    // Each 30-min slot is 50 pixels
    const slotHeight = 50.0;
    final targetHour =
        currentHour.clamp(viewModel.openHour, viewModel.closeHour - 1);
    final scrollPosition = (targetHour - viewModel.openHour) * 2 * slotHeight;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingViewModel>();

    if (viewModel.state == BookingViewState.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: _buildTimelineContent(viewModel),
    );
  }

  Widget _buildTimelineContent(BookingViewModel viewModel) {
    const slotHeight = 50.0;
    const timeColumnWidth = 55.0;
    final now = DateTime.now();
    final isToday = viewModel.selectedDate.day == now.day &&
        viewModel.selectedDate.month == now.month &&
        viewModel.selectedDate.year == now.year;

    // Generate all 30-minute slots
    final slots = <_SlotInfo>[];
    for (int hour = viewModel.openHour; hour < viewModel.closeHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        slots.add(_SlotInfo(hour: hour, minute: minute));
      }
    }

    return Stack(
      children: [
        // Grid lines and time slots
        Column(
          children: slots.map((slot) {
            return _TimeSlotRow(
              hour: slot.hour,
              minute: slot.minute,
              slotHeight: slotHeight,
              timeColumnWidth: timeColumnWidth,
              viewModel: viewModel,
            );
          }).toList(),
        ),

        // Current time indicator
        if (isToday)
          _CurrentTimeIndicator(
            openHour: viewModel.openHour,
            closeHour: viewModel.closeHour,
            slotHeight: slotHeight,
            timeColumnWidth: timeColumnWidth,
          ),
      ],
    );
  }
}

class _SlotInfo {
  final int hour;
  final int minute;
  _SlotInfo({required this.hour, required this.minute});
}

/// Single 30-minute time slot row
class _TimeSlotRow extends StatelessWidget {
  final int hour;
  final int minute;
  final double slotHeight;
  final double timeColumnWidth;
  final BookingViewModel viewModel;

  const _TimeSlotRow({
    required this.hour,
    required this.minute,
    required this.slotHeight,
    required this.timeColumnWidth,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final isHourStart = minute == 0;
    final subCourtIndex = viewModel.selectedSubCourtIndex;

    final isPassed = viewModel.isSlotPassed(hour, minute);
    final isBooked = viewModel.isSlotBooked(subCourtIndex, hour, minute);
    final isSelected = viewModel.isSlotSelected(subCourtIndex, hour, minute);
    final slot = viewModel.getBookingForSlot(subCourtIndex, hour, minute);
    final isDisabled = isPassed || isBooked;

    return SizedBox(
      height: slotHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: timeColumnWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 0),
                child: Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isHourStart ? FontWeight.w500 : FontWeight.normal,
                    color: isPassed ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),

          // Time slot area
          Expanded(
            child: GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      viewModel.toggleSlotSelection(subCourtIndex, hour, minute);
                    },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isHourStart
                          ? Colors.grey.shade300
                          : Colors.grey.shade200,
                      width: isHourStart ? 1 : 0.5,
                    ),
                    left: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: _buildSlotContent(isPassed, isBooked, isSelected, slot),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotContent(bool isPassed, bool isBooked, bool isSelected, dynamic slot) {
    // Passed time slot - disabled
    if (isPassed) {
      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(
            Icons.block,
            color: Colors.grey.shade400,
            size: 16,
          ),
        ),
      );
    }

    // Booked slot
    if (isBooked) {
      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'Booked',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Selected slot
    if (isSelected) {
      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFFA5D6A7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF4CAF50)),
        ),
        child: const Center(
          child: Icon(
            Icons.check,
            color: Color(0xFF2E7D32),
            size: 20,
          ),
        ),
      );
    }

    // Empty slot - available for selection
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Current time indicator (red line)
class _CurrentTimeIndicator extends StatelessWidget {
  final int openHour;
  final int closeHour;
  final double slotHeight;
  final double timeColumnWidth;

  const _CurrentTimeIndicator({
    required this.openHour,
    required this.closeHour,
    required this.slotHeight,
    required this.timeColumnWidth,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    // Only show if current time is within operating hours
    if (currentHour < openHour || currentHour >= closeHour) {
      return const SizedBox.shrink();
    }

    // Calculate position based on 30-min slots
    final slotsFromOpen = (currentHour - openHour) * 2 + (currentMinute / 30);
    final topOffset = slotsFromOpen * slotHeight;

    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Row(
        children: [
          SizedBox(width: timeColumnWidth - 8),
          // Time label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Red line
          Expanded(
            child: Container(
              height: 2,
              color: const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom bar with booking summary and confirm button
class _BottomBookingBar extends StatelessWidget {
  const _BottomBookingBar();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingViewModel>();
    final selection = viewModel.selection;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
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
          // Selection info
          Expanded(
            child: selection.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${selection.slotCount} slots',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${selection.courtCount} ${selection.courtCount == 1 ? 'sân' : 'sân'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Show validation message or price info
                      if (viewModel.bookingValidationMessage != null)
                        Text(
                          viewModel.bookingValidationMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE57373),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text(
                              selection.durationFormatted,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '|',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              BookingViewModel.formatPriceVND(viewModel.totalPrice),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                : Text(
                    'Chọn khung giờ (tối thiểu 1 giờ)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // Clear button (if has selection)
          if (selection.isNotEmpty)
            TextButton(
              onPressed: () => viewModel.clearSelection(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Clear'),
            ),

          const SizedBox(width: 8),

          // Book now button
          ElevatedButton(
            onPressed: viewModel.canBook
                ? () => _navigateToConfirmation(context, viewModel)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'BOOK NOW',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: viewModel.canBook ? Colors.white : Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToConfirmation(BuildContext context, BookingViewModel viewModel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingConfirmationView(
          court: viewModel.court,
          formattedDate: viewModel.formattedDate,
          apiFormattedDate: viewModel.apiFormattedDate,
          summaries: viewModel.bookingSummaries,
          totalPrice: viewModel.totalPrice,
          totalDuration: viewModel.totalDurationFormatted,
          subCourts: viewModel.subCourts,
        ),
      ),
    );
  }
}
